# ============================================================================
# PDF/OCR Tools Partial
# ============================================================================
# Complete toolkit for PDF processing, OCR, and form filling
# All tools from Debian repositories (proxy-friendly)
# ============================================================================

USER root

# Install PDF processing tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    # PDF utilities (poppler-utils: pdftotext, pdfimages, etc.)
    poppler-utils \
    # PDF manipulation (ghostscript: compress, convert)
    ghostscript \
    # PDF toolkit (qpdf: merge, split, encrypt)
    qpdf \
    # OCR engine (tesseract: text recognition from images)
    tesseract-ocr \
    tesseract-ocr-eng \
    # OCR for PDFs (ocrmypdf: make scanned PDFs searchable)
    ocrmypdf \
    # PDF form filling (pdftk: fill forms programmatically)
    pdftk \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

USER node
