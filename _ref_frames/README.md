# Frames de referencia (vídeo)

PNG extraídos del vídeo de referencia con:

```powershell
ffmpeg -y -i "RUTA\video.mp4" -vf "fps=1,scale=640:-1" -frames:v 8 "_ref_frames/ref_%03d.png"
```

Sirven para comparar el pipeline del juego (SubViewport + outlines + post) con el devlog de destino.
