# Subir el proyecto a GitHub

En esta máquina **`gh` no tenía sesión** la última vez que se comprobó. Haz una vez:

```powershell
gh auth login
```

(Sigue el asistente: GitHub.com → HTTPS → login por navegador.)

Luego, en la carpeta del proyecto:

```powershell
cd "C:\Users\bruni\OneDrive\Desktop\Programming Brunich\Friends\IArogue3D Godot"
git status
git remote add origin https://github.com/TU_USUARIO/TU_REPO.git
git branch -M main
git push -u origin main
```

**Crear repo nuevo desde cero** (si aún no existe):

```powershell
gh repo create ia-rogue-3d-godot --private --source=. --remote=origin --push
```

Cambia el nombre del repo si quieres. Para ramas de trabajo:

```powershell
git checkout -b art/pipeline-tune
git push -u origin art/pipeline-tune
```
