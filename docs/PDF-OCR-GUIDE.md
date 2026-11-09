# PDF & OCR Tools Guide

This guide covers the PDF processing and OCR tools included in yolo-docker-maxxing.

## Tools Overview

| Tool | Purpose | Key Commands |
|------|---------|--------------|
| poppler-utils | PDF utilities | `pdftotext`, `pdfimages`, `pdfinfo` |
| ghostscript | PDF manipulation | `gs` (compress, convert) |
| qpdf | PDF toolkit | Merge, split, encrypt PDFs |
| tesseract | OCR engine | Text recognition from images |
| ocrmypdf | OCR for PDFs | Make scanned PDFs searchable |
| pdftk | Form filling | Fill PDF forms programmatically |

## Common Tasks

### Extract Text from PDF
```bash
pdftotext document.pdf output.txt
```

### Extract Images from PDF
```bash
pdfimages document.pdf output-prefix
```

### Compress PDF
```bash
gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dPDFSETTINGS=/ebook \
   -dNOPAUSE -dQUIET -dBATCH -sOutputFile=compressed.pdf input.pdf
```

Quality settings: `/screen` (low), `/ebook` (medium), `/printer` (high), `/prepress` (highest)

### Merge PDFs
```bash
qpdf --empty --pages file1.pdf file2.pdf file3.pdf -- merged.pdf
```

### Split PDF
```bash
qpdf input.pdf --pages . 1-10 -- first-10-pages.pdf
```

### OCR Scanned PDF (Make Searchable)
```bash
ocrmypdf scanned.pdf searchable.pdf
```

### Fill PDF Form
```bash
pdftk form.pdf fill_form data.fdf output filled.pdf
```

## Python Integration

All these tools can be called from Python using subprocess:

```python
import subprocess

# Extract text
subprocess.run(['pdftotext', 'input.pdf', 'output.txt'])

# OCR with error handling
result = subprocess.run(
    ['ocrmypdf', 'scanned.pdf', 'searchable.pdf'],
    capture_output=True,
    text=True
)
if result.returncode == 0:
    print("OCR successful")
else:
    print(f"Error: {result.stderr}")
```

## References

- [Poppler utilities](https://poppler.freedesktop.org/)
- [Ghostscript docs](https://www.ghostscript.com/doc/)
- [QPDF manual](https://qpdf.readthedocs.io/)
- [Tesseract OCR](https://github.com/tesseract-ocr/tesseract)
- [OCRmyPDF](https://ocrmypdf.readthedocs.io/)
