import std/[httpclient, os, strutils, strformat, uri, dirs]
import zippy/ziparchives


proc downloadOpencvSource*(version: string, downloadPath: string) =
  ## Downloads and extracts an OpenCV release from GitHub
  ## 
  ## Parameters:
  ##   version: OpenCV version (e.g. "4.9.0", "5.0.0-alpha")
  ##   downloadPath: Directory to download and extract to
  let opencv_modules = [
    "core", "calib3d", "dnn", "features2d", "flann", "gapi", "highgui",
    "imgcodecs", "imgproc", "ml", "objdetect", "photo", "stitching", "video",
    "videoio"
  ]
  # Create directory if needed
  if not dirExists(downloadPath):
    createDir(downloadPath)
    echo "📂 Creating download path..."
  else:
    raise newException(Exception, "Download directory already exists")
  let
    repo = "opencv/opencv"
    zipName = "opencv-" & version & ".zip"
    zipPath = downloadPath / zipName
    extractPath = downloadPath / "unzipped"
    downloadUrl = parseUri(&"https://github.com/{repo}/archive/refs/tags/{version}.zip")
  echo "📥 Downloading the OpenCV source code..."
  # Download with HTTP client
  var client = newHttpClient()
  defer: client.close()
  try:
    client.downloadFile($downloadUrl, zipPath)
  except HttpRequestError as e:
    raise newException(IOError, "Download failed: " & e.msg)
  echo "📦 Extracting the zip file..."
  extractAll(zipPath, extractPath)
  # Copy only the header of the modules for the bindings
  for _, path in walkDir(extractPath / "opencv-" & version / "modules"):
    if path.lastPathPart() in opencv_modules:
      for _, subPath in walkDir(path):
        if subPath.lastPathPart() == "include":
          for inclPath in walkDir(subPath / "opencv2"):
            if inclPath.kind == pcDir:
              moveDir(inclPath.path, downloadPath / inclPath.path.lastPathPart())
            elif inclPath.kind == pcFile:
              moveFile(inclPath.path, downloadPath / inclPath.path.lastPathPart())
  # Cleanup temporary files
  removeDir(extractPath)
  removeFile(zipPath)
  echo &"✅ Successfully downloaded and extracted OpenCV {version} to {downloadPath}"