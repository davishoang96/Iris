export interface Photo {
  id: string;
  w: number;
  h: number;
  size: string;
  date: string;
  camera: string;
  lens: string;
  focal: string;
  aperture: string;
  shutter: string;
  iso: number;
  title: string;
  location: string;
  gps: string;
  profile: string;
  rating: number;
  full: string;
  thumb: string;
  aspect: number;
}

interface RawPhoto extends Omit<Photo, "full" | "thumb" | "aspect"> {
  src: string;
}

const u = (id: string, w = 2000) =>
  `https://images.unsplash.com/photo-${id}?auto=format&fit=crop&w=${w}&q=80`;

const raw: RawPhoto[] = [
  { id: "DSCF1042", src: "1506905925346-21bda4d32df4", w: 6000, h: 4000, size: "12.4 MB", date: "Jul 18, 2025  ·  06:42", camera: "FUJIFILM X-T5", lens: "XF 16-55mm f/2.8 R LM WR", focal: "23mm", aperture: "f/8.0", shutter: "1/250s", iso: 200, title: "Reynisfjara at dawn", location: "Vík í Mýrdal, Iceland", gps: "63.4060° N, 19.0451° W", profile: "Display P3", rating: 5 },
  { id: "DSCF1043", src: "1531366936337-7c912a4589a7", w: 6000, h: 4000, size: "10.8 MB", date: "Jul 18, 2025  ·  07:12", camera: "FUJIFILM X-T5", lens: "XF 16-55mm f/2.8 R LM WR", focal: "55mm", aperture: "f/5.6", shutter: "1/500s", iso: 200, title: "Basalt columns", location: "Reynisfjara, Iceland", gps: "63.4060° N, 19.0451° W", profile: "Display P3", rating: 4 },
  { id: "DSCF1044", src: "1500534314209-a25ddb2bd429", w: 6000, h: 4000, size: "11.2 MB", date: "Jul 18, 2025  ·  09:03", camera: "FUJIFILM X-T5", lens: "XF 23mm f/1.4 R LM WR", focal: "23mm", aperture: "f/2.8", shutter: "1/1000s", iso: 160, title: "Glacial outwash", location: "Sólheimasandur, Iceland", gps: "63.4914° N, 19.3641° W", profile: "Display P3", rating: 3 },
  { id: "DSCF1045", src: "1464822759023-fed622ff2c3b", w: 6000, h: 4000, size: "13.9 MB", date: "Jul 18, 2025  ·  11:21", camera: "FUJIFILM X-T5", lens: "XF 16-55mm f/2.8 R LM WR", focal: "16mm", aperture: "f/11", shutter: "1/320s", iso: 125, title: "Skógafoss mist", location: "Skógar, Iceland", gps: "63.5320° N, 19.5114° W", profile: "Display P3", rating: 5 },
  { id: "DSCF1046", src: "1483728642387-6c3bdd6c93e5", w: 6000, h: 4000, size: "9.7 MB", date: "Jul 18, 2025  ·  14:48", camera: "FUJIFILM X-T5", lens: "XF 23mm f/1.4 R LM WR", focal: "23mm", aperture: "f/4.0", shutter: "1/800s", iso: 160, title: "Moss field", location: "Eldhraun lava field", gps: "63.7833° N, 18.0833° W", profile: "Display P3", rating: 4 },
  { id: "DSCF1047", src: "1418065460487-3e41a6c84dc5", w: 6000, h: 4000, size: "14.6 MB", date: "Jul 18, 2025  ·  16:02", camera: "FUJIFILM X-T5", lens: "XF 70-300mm f/4-5.6", focal: "180mm", aperture: "f/8.0", shutter: "1/640s", iso: 200, title: "Highland ridge", location: "Landmannalaugar, Iceland", gps: "63.9930° N, 19.0667° W", profile: "Display P3", rating: 5 },
  { id: "DSCF1048", src: "1469854523086-cc02fe5d8800", w: 6000, h: 4000, size: "11.8 MB", date: "Jul 18, 2025  ·  18:55", camera: "FUJIFILM X-T5", lens: "XF 16-55mm f/2.8 R LM WR", focal: "35mm", aperture: "f/5.6", shutter: "1/400s", iso: 200, title: "Golden hour fjord", location: "Seyðisfjörður, Iceland", gps: "65.2627° N, 13.9942° W", profile: "Display P3", rating: 4 },
  { id: "DSCF1049", src: "1441974231531-c6227db76b6e", w: 6000, h: 4000, size: "10.2 MB", date: "Jul 18, 2025  ·  19:14", camera: "FUJIFILM X-T5", lens: "XF 16-55mm f/2.8 R LM WR", focal: "16mm", aperture: "f/8.0", shutter: "1/250s", iso: 200, title: "Pine cathedral", location: "Hallormsstaður Forest", gps: "65.0833° N, 14.7333° W", profile: "Display P3", rating: 3 },
  { id: "DSCF1050", src: "1454496522488-7a8e488e8606", w: 6000, h: 4000, size: "12.0 MB", date: "Jul 19, 2025  ·  05:38", camera: "FUJIFILM X-T5", lens: "XF 70-300mm f/4-5.6", focal: "300mm", aperture: "f/6.4", shutter: "1/1000s", iso: 400, title: "Mountain lake", location: "Þórsmörk, Iceland", gps: "63.6833° N, 19.4833° W", profile: "Display P3", rating: 5 },
  { id: "DSCF1051", src: "1470770841072-f978cf4d019e", w: 6000, h: 4000, size: "11.4 MB", date: "Jul 19, 2025  ·  08:21", camera: "FUJIFILM X-T5", lens: "XF 16-55mm f/2.8 R LM WR", focal: "24mm", aperture: "f/8.0", shutter: "1/500s", iso: 160, title: "Cabin and the lake", location: "Kirkjufell, Iceland", gps: "64.9417° N, 23.3072° W", profile: "Display P3", rating: 5 },
  { id: "DSCF1052", src: "1418985991508-e47386d96a71", w: 6000, h: 4000, size: "13.1 MB", date: "Jul 19, 2025  ·  10:47", camera: "FUJIFILM X-T5", lens: "XF 23mm f/1.4 R LM WR", focal: "23mm", aperture: "f/2.0", shutter: "1/1250s", iso: 125, title: "Coastal cliff", location: "Látrabjarg, Iceland", gps: "65.5028° N, 24.5328° W", profile: "Display P3", rating: 4 },
  { id: "DSCF1053", src: "1444090542259-0af8fa96557e", w: 6000, h: 4000, size: "9.4 MB", date: "Jul 19, 2025  ·  12:33", camera: "FUJIFILM X-T5", lens: "XF 16-55mm f/2.8 R LM WR", focal: "55mm", aperture: "f/4.0", shutter: "1/640s", iso: 200, title: "Wildflowers", location: "Westfjords, Iceland", gps: "65.9833° N, 22.5333° W", profile: "Display P3", rating: 3 },
  { id: "DSCF1054", src: "1501785888041-af3ef285b470", w: 6000, h: 4000, size: "12.8 MB", date: "Jul 19, 2025  ·  14:18", camera: "FUJIFILM X-T5", lens: "XF 16-55mm f/2.8 R LM WR", focal: "16mm", aperture: "f/11", shutter: "1/320s", iso: 200, title: "Hallsanef", location: "Faroe Islands", gps: "62.0000° N, 6.7833° W", profile: "Display P3", rating: 5 },
  { id: "DSCF1055", src: "1493246507139-91e8fad9978e", w: 6000, h: 4000, size: "10.6 MB", date: "Jul 19, 2025  ·  17:02", camera: "FUJIFILM X-T5", lens: "XF 70-300mm f/4-5.6", focal: "210mm", aperture: "f/5.6", shutter: "1/800s", iso: 320, title: "Distant ridges", location: "Streymoy, Faroe Islands", gps: "62.1167° N, 7.0500° W", profile: "Display P3", rating: 4 },
  { id: "DSCF1056", src: "1470770903676-69b98201ea1c", w: 6000, h: 4000, size: "11.9 MB", date: "Jul 19, 2025  ·  19:48", camera: "FUJIFILM X-T5", lens: "XF 23mm f/1.4 R LM WR", focal: "23mm", aperture: "f/4.0", shutter: "1/500s", iso: 200, title: "Lake at dusk", location: "Sørvágsvatn, Faroe Islands", gps: "62.0833° N, 7.2833° W", profile: "Display P3", rating: 5 },
  { id: "DSCF1057", src: "1431794062232-2a99a5431c6c", w: 6000, h: 4000, size: "13.4 MB", date: "Jul 20, 2025  ·  06:13", camera: "FUJIFILM X-T5", lens: "XF 16-55mm f/2.8 R LM WR", focal: "35mm", aperture: "f/5.6", shutter: "1/400s", iso: 160, title: "Sea stacks", location: "Drangarnir, Faroe Islands", gps: "62.0667° N, 7.3333° W", profile: "Display P3", rating: 5 },
  { id: "DSCF1058", src: "1502082553048-f009c37129b9", w: 6000, h: 4000, size: "10.1 MB", date: "Jul 20, 2025  ·  08:55", camera: "FUJIFILM X-T5", lens: "XF 16-55mm f/2.8 R LM WR", focal: "16mm", aperture: "f/8.0", shutter: "1/640s", iso: 200, title: "Birch grove", location: "Þingvellir, Iceland", gps: "64.2559° N, 21.1297° W", profile: "Display P3", rating: 3 },
  { id: "DSCF1059", src: "1500964757637-c85e8a162699", w: 6000, h: 4000, size: "12.5 MB", date: "Jul 20, 2025  ·  11:30", camera: "FUJIFILM X-T5", lens: "XF 70-300mm f/4-5.6", focal: "100mm", aperture: "f/5.6", shutter: "1/800s", iso: 200, title: "River bend", location: "Skaftafell, Iceland", gps: "64.0167° N, 16.9667° W", profile: "Display P3", rating: 4 },
  { id: "DSCF1060", src: "1505873242700-f289a29e1e0f", w: 6000, h: 4000, size: "11.0 MB", date: "Jul 20, 2025  ·  14:08", camera: "FUJIFILM X-T5", lens: "XF 23mm f/1.4 R LM WR", focal: "23mm", aperture: "f/2.8", shutter: "1/1000s", iso: 160, title: "Coast line", location: "Snæfellsnes, Iceland", gps: "64.8833° N, 23.7833° W", profile: "Display P3", rating: 4 },
  { id: "DSCF1061", src: "1470071459604-3b5ec3a7fe05", w: 6000, h: 4000, size: "14.2 MB", date: "Jul 20, 2025  ·  20:14", camera: "FUJIFILM X-T5", lens: "XF 16-55mm f/2.8 R LM WR", focal: "23mm", aperture: "f/8.0", shutter: "30s", iso: 800, title: "Aurora over Vík", location: "Vík í Mýrdal, Iceland", gps: "63.4194° N, 19.0061° W", profile: "Display P3", rating: 5 },
];

export const PHOTOS: Photo[] = raw.map(({ src, ...p }) => ({
  ...p,
  full: u(src, 2000),
  thumb: u(src, 240),
  aspect: p.w / p.h,
}));
