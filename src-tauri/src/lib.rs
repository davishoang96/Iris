use serde::Serialize;
use std::fs;
use std::io::{BufReader, Read, Seek, SeekFrom};
use std::path::{Path, PathBuf};
use tauri_plugin_dialog::DialogExt;

#[derive(Serialize)]
pub struct PhotoMeta {
    pub path: String,
    pub name: String,
    pub size: String,
    pub width: u32,
    pub height: u32,
    pub date: String,
    pub camera: String,
    pub lens: String,
    pub focal: String,
    pub aperture: String,
    pub shutter: String,
    pub iso: u32,
    pub gps: String,
    pub profile: String,
    pub rating: u8,
}

const IMAGE_EXTS: &[&str] = &[
    "jpg", "jpeg", "png", "raf", "heic", "heif",
    "tiff", "tif", "dng", "nef", "cr2", "cr3", "arw",
];

fn format_size(bytes: u64) -> String {
    let mb = bytes as f64 / 1_000_000.0;
    format!("{:.1} MB", mb)
}

fn format_exif_date(s: &str) -> String {
    let months = [
        "Jan", "Feb", "Mar", "Apr", "May", "Jun",
        "Jul", "Aug", "Sep", "Oct", "Nov", "Dec",
    ];
    let s = s.trim_matches('"').trim();
    let parts: Vec<&str> = s.splitn(2, ' ').collect();
    if parts.len() != 2 {
        return s.to_string();
    }
    let date_parts: Vec<&str> = parts[0].split(':').collect();
    if date_parts.len() != 3 {
        return s.to_string();
    }
    let year = date_parts[0];
    let month: usize = date_parts[1].parse().unwrap_or(1);
    let day: u32 = date_parts[2].parse().unwrap_or(1);
    let time_parts: Vec<&str> = parts[1].split(':').collect();
    let hhmm = if time_parts.len() >= 2 {
        format!("{}:{}", time_parts[0], time_parts[1])
    } else {
        parts[1].to_string()
    };
    let mon = months.get(month.saturating_sub(1)).copied().unwrap_or("");
    format!("{} {}, {}  ·  {}", mon, day, year, hhmm)
}

/// Extract the embedded full-size JPEG from a Fujifilm RAF file.
/// RAF layout: magic[16] | version[4] | camera[8] | dir_ver[4] | pad[20] |
///             jpeg_offset[4] | jpeg_len[4]  (all big-endian, offsets at 84/88)
fn extract_raf_jpeg(path: &Path) -> Option<Vec<u8>> {
    let mut f = fs::File::open(path).ok()?;
    let mut magic = [0u8; 16];
    f.read_exact(&mut magic).ok()?;
    if &magic != b"FUJIFILMCCD-RAW " {
        return None;
    }
    f.seek(SeekFrom::Start(84)).ok()?;
    let mut buf4 = [0u8; 4];
    f.read_exact(&mut buf4).ok()?;
    let jpeg_off = u32::from_be_bytes(buf4) as u64;
    f.read_exact(&mut buf4).ok()?;
    let jpeg_len = u32::from_be_bytes(buf4) as usize;
    if jpeg_len == 0 {
        return None;
    }
    f.seek(SeekFrom::Start(jpeg_off)).ok()?;
    let mut data = vec![0u8; jpeg_len];
    f.read_exact(&mut data).ok()?;
    if data.starts_with(&[0xFF, 0xD8]) { Some(data) } else { None }
}

/// Extract a JPEG preview from a TIFF-based RAW file (DNG, NEF, CR2, ARW, ORF…)
/// by reading JPEGInterchangeFormat / JPEGInterchangeFormatLength from the EXIF.
fn extract_tiff_jpeg(path: &Path) -> Option<Vec<u8>> {
    let file = fs::File::open(path).ok()?;
    let mut buf = BufReader::new(file);
    let ex = exif::Reader::new().read_from_container(&mut buf).ok()?;

    // Try IFD1 (thumbnail) first, then PRIMARY, across both.
    for ifd in [exif::In::THUMBNAIL, exif::In::PRIMARY] {
        let offset = ex
            .get_field(exif::Tag::JPEGInterchangeFormat, ifd)
            .and_then(|f| match &f.value {
                exif::Value::Long(v) => v.first().copied(),
                _ => None,
            });
        let length = ex
            .get_field(exif::Tag::JPEGInterchangeFormatLength, ifd)
            .and_then(|f| match &f.value {
                exif::Value::Long(v) => v.first().copied(),
                _ => None,
            });

        if let (Some(off), Some(len)) = (offset, length) {
            if len == 0 {
                continue;
            }
            let mut f = fs::File::open(path).ok()?;
            f.seek(SeekFrom::Start(off as u64)).ok()?;
            let mut data = vec![0u8; len as usize];
            if f.read_exact(&mut data).is_ok() && data.starts_with(&[0xFF, 0xD8]) {
                return Some(data);
            }
        }
    }
    None
}

/// For RAW formats not natively renderable by WebKit, extract/cache a JPEG
/// preview in the system temp dir. Returns display path (may differ from source).
fn display_path(original: &Path) -> PathBuf {
    let ext = original
        .extension()
        .map(|e| e.to_string_lossy().to_lowercase())
        .unwrap_or_default();

    // Formats WebKit renders natively — serve directly.
    if matches!(ext.as_str(), "jpg" | "jpeg" | "png" | "webp" | "gif" | "heic" | "heif") {
        return original.to_owned();
    }

    // Derive a stable temp-file name from the source path.
    use std::hash::Hash;
    let mut h = std::collections::hash_map::DefaultHasher::new();
    original.hash(&mut h);
    let hash = std::hash::Hasher::finish(&h);
    let preview = std::env::temp_dir().join(format!("see_{:016x}.jpg", hash));

    if preview.exists() {
        return preview;
    }

    let extracted = match ext.as_str() {
        "raf" => extract_raf_jpeg(original),
        // TIFF-based: DNG, NEF, CR2, CR3, ARW, ORF, RW2, …
        _ => extract_tiff_jpeg(original),
    };

    if let Some(jpeg) = extracted {
        if fs::write(&preview, jpeg).is_ok() {
            return preview;
        }
    }

    // Fallback: serve original and let the browser show a broken image.
    original.to_owned()
}

fn percent_decode(s: &str) -> String {
    let mut bytes: Vec<u8> = Vec::with_capacity(s.len());
    let mut chars = s.chars();
    while let Some(c) = chars.next() {
        if c == '%' {
            let h1 = chars.next().and_then(|c| c.to_digit(16));
            let h2 = chars.next().and_then(|c| c.to_digit(16));
            if let (Some(h1), Some(h2)) = (h1, h2) {
                bytes.push((h1 * 16 + h2) as u8);
                continue;
            }
        }
        let mut buf = [0u8; 4];
        bytes.extend_from_slice(c.encode_utf8(&mut buf).as_bytes());
    }
    String::from_utf8_lossy(&bytes).into_owned()
}

fn rational_f64(r: &exif::Rational) -> f64 {
    if r.denom == 0 { 0.0 } else { r.num as f64 / r.denom as f64 }
}

fn get_u32_field(ex: &exif::Exif, tag: exif::Tag) -> Option<u32> {
    ex.get_field(tag, exif::In::PRIMARY).and_then(|f| match &f.value {
        exif::Value::Short(v) => v.first().map(|&n| n as u32),
        exif::Value::Long(v) => v.first().copied(),
        _ => None,
    })
}

fn get_str_field(ex: &exif::Exif, tag: exif::Tag) -> String {
    ex.get_field(tag, exif::In::PRIMARY)
        .map(|f| f.display_value().to_string().trim_matches('"').trim().to_string())
        .unwrap_or_default()
}

fn build_photo_meta(path: &Path) -> Option<PhotoMeta> {
    let md = fs::metadata(path).ok()?;
    if !md.is_file() {
        return None;
    }
    let ext = path.extension()?.to_string_lossy().to_lowercase();
    if !IMAGE_EXTS.contains(&ext.as_str()) {
        return None;
    }

    let name = path.file_name()?.to_string_lossy().into_owned();
    let size = format_size(md.len());
    let disp = display_path(path);

    let exif_opt = fs::File::open(path)
        .ok()
        .map(BufReader::new)
        .and_then(|mut r| exif::Reader::new().read_from_container(&mut r).ok());

    let (width, height, camera, lens, focal, aperture, shutter, iso, date, profile) =
        match exif_opt.as_ref() {
            None => (0, 0, String::new(), String::new(), String::new(), String::new(), String::new(), 0u32, String::new(), String::new()),
            Some(ex) => {
                let width = get_u32_field(ex, exif::Tag::PixelXDimension).unwrap_or(0);
                let height = get_u32_field(ex, exif::Tag::PixelYDimension).unwrap_or(0);

                let make = get_str_field(ex, exif::Tag::Make);
                let model = get_str_field(ex, exif::Tag::Model);
                let camera = match (make.is_empty(), model.is_empty()) {
                    (true, _) => model,
                    (_, true) => make,
                    _ => format!("{} {}", make, model),
                };

                let lens = get_str_field(ex, exif::Tag::LensModel);

                let focal = ex.get_field(exif::Tag::FocalLength, exif::In::PRIMARY)
                    .and_then(|f| match &f.value {
                        exif::Value::Rational(v) => v.first().map(|r| {
                            let mm = rational_f64(r);
                            if mm.fract() == 0.0 { format!("{}mm", mm as u32) }
                            else { format!("{:.1}mm", mm) }
                        }),
                        _ => None,
                    })
                    .unwrap_or_default();

                let aperture = ex.get_field(exif::Tag::FNumber, exif::In::PRIMARY)
                    .and_then(|f| match &f.value {
                        exif::Value::Rational(v) => v.first().map(|r| format!("f/{:.1}", rational_f64(r))),
                        _ => None,
                    })
                    .unwrap_or_default();

                let shutter = ex.get_field(exif::Tag::ExposureTime, exif::In::PRIMARY)
                    .and_then(|f| match &f.value {
                        exif::Value::Rational(v) => v.first().map(|r| {
                            if r.denom == 1 { format!("{}s", r.num) }
                            else { format!("{}/{}s", r.num, r.denom) }
                        }),
                        _ => None,
                    })
                    .unwrap_or_default();

                let iso = get_u32_field(ex, exif::Tag::PhotographicSensitivity).unwrap_or(0);

                let raw_date = get_str_field(ex, exif::Tag::DateTimeOriginal);
                let date = if raw_date.is_empty() { String::new() } else { format_exif_date(&raw_date) };

                let profile = String::from("sRGB");

                (width, height, camera, lens, focal, aperture, shutter, iso, date, profile)
            }
        };

    Some(PhotoMeta {
        path: disp.to_string_lossy().into_owned(),
        name,
        size,
        width,
        height,
        date,
        camera,
        lens,
        focal,
        aperture,
        shutter,
        iso,
        gps: String::new(),
        profile,
        rating: 0,
    })
}

#[tauri::command]
async fn open_folder(app: tauri::AppHandle) -> Option<String> {
    let (tx, rx) = std::sync::mpsc::sync_channel::<Option<String>>(1);
    app.dialog().file().pick_folder(move |result| {
        let path = result
            .and_then(|fp| fp.as_path().map(|p| p.to_string_lossy().into_owned()));
        let _ = tx.send(path);
    });
    tauri::async_runtime::spawn_blocking(move || rx.recv().ok().flatten())
        .await
        .ok()
        .flatten()
}

#[tauri::command]
fn list_images(folder: String) -> Result<Vec<PhotoMeta>, String> {
    let dir = PathBuf::from(&folder);
    if !dir.is_dir() {
        return Err(format!("not a directory: {}", folder));
    }
    let mut photos: Vec<PhotoMeta> = fs::read_dir(&dir)
        .map_err(|e| e.to_string())?
        .filter_map(|e| e.ok())
        .filter_map(|e| build_photo_meta(&e.path()))
        .collect();
    photos.sort_by(|a, b| a.name.cmp(&b.name));
    Ok(photos)
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .plugin(tauri_plugin_opener::init())
        .plugin(tauri_plugin_dialog::init())
        .register_uri_scheme_protocol("localfile", |_app, request| {
            let raw_path = request.uri().path().to_string();
            let path = percent_decode(&raw_path);
            let data = fs::read(&path).unwrap_or_default();
            let ext = Path::new(&path)
                .extension()
                .map(|e| e.to_string_lossy().to_lowercase())
                .unwrap_or_default();
            let mime = match ext.as_str() {
                "jpg" | "jpeg" => "image/jpeg",
                "png"          => "image/png",
                "gif"          => "image/gif",
                "webp"         => "image/webp",
                "heic" | "heif" => "image/heic",
                "tiff" | "tif" => "image/tiff",
                _              => "application/octet-stream",
            };
            tauri::http::Response::builder()
                .header("Content-Type", mime)
                .body(data)
                .unwrap()
        })
        .invoke_handler(tauri::generate_handler![open_folder, list_images])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
