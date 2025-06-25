# PDF Trusted Converter

A shell script for macOS that converts PDFs to a "trusted" format by converting them to images and back to PDF, similar to Qubes OS's `qvm-convert-pdf` functionality. This process removes potentially dangerous elements like JavaScript, embedded files, forms, and links while preserving the visual content.

## Features

- **Security-focused**: Removes JavaScript, forms, links, and other potentially malicious elements
- **Image-based conversion**: Converts PDF pages to images and reconstructs a new PDF
- **Batch processing**: Support for batch mode with automatic filename generation
- **Configurable quality**: Adjustable DPI settings for different quality needs
- **Progress tracking**: Colored output with detailed progress information
- **Error handling**: Comprehensive dependency checking and error reporting
- **PDF optimization**: Automatic optimization of the output PDF using Ghostscript

## Security Benefits

- ✅ **Removes malicious JavaScript**
- ✅ **Eliminates embedded files and attachments**
- ✅ **Strips out interactive forms**
- ✅ **Removes hyperlinks and actions**
- ✅ **Neutralizes potential exploits**

⚠️ **Trade-offs:**

- Text becomes non-selectable (embedded as images)
  - Search functionality is lost
  - File size may increase
  - Accessibility features are removed

## Prerequisites

The script requires ImageMagick and Ghostscript to be installed:

```bash
# Install using Homebrew
brew install imagemagick ghostscript
```

## Installation

1. Download the script:

```bash
curl -O https://raw.githubusercontent.com/sora-grayscale/pdf-trusted-converter/main/pdf-trusted-converter.sh
```

2. Make it executable:

```bash
chmod +x pdf-trusted-converter.sh
```

3. Optionally, move to a directory in your PATH:

```bash
sudo mv pdf-trusted-converter.sh /usr/local/bin/pdf-trusted-converter
```

## Usage

### Basic Usage

```bash
# Convert a PDF to trusted format
./pdf-trusted-converter.sh input.pdf output.pdf

# If no output filename is specified, adds .trusted suffix
./pdf-trusted-converter.sh document.pdf
# Creates: document.trusted.pdf
```

### Batch Mode

```bash
# Batch mode: automatically generates output filename
./pdf-trusted-converter.sh --batch document.pdf
# Creates: document.trusted.pdf
```

### Advanced Options

```bash
# High quality conversion (600 DPI)
./pdf-trusted-converter.sh -d 600 document.pdf high_quality.pdf

# Verbose output for debugging
./pdf-trusted-converter.sh -v document.pdf output.pdf

# Combine options
./pdf-trusted-converter.sh --batch -d 450 -v document.pdf
```

### Command Line Options

| Option          | Description                             | Default |
| --------------- | --------------------------------------- | ------- |
| `-d, --dpi DPI` | Set DPI for image conversion            | 300     |
| `-b, --batch`   | Batch mode with auto-generated filename | false   |
| `-v, --verbose` | Enable verbose output                   | false   |
| `-h, --help`    | Show help message                       | -       |

## Examples

### Convert a suspicious PDF from email

```bash
./pdf-trusted-converter.sh suspicious_attachment.pdf safe_document.pdf
```

### Batch process multiple PDFs

```bash
# Create a simple loop for multiple files
for pdf in *.pdf; do
  ./pdf-trusted-converter.sh --batch "$pdf"
done
```

### High-quality conversion for documents with small text

```bash
./pdf-trusted-converter.sh -d 600 technical_document.pdf readable_output.pdf
```

## How It Works

1. **Dependency Check**: Verifies that ImageMagick and Ghostscript are installed
2. **PDF to Images**: Converts each PDF page to high-resolution PNG images
3. **Image to PDF**: Reconstructs a new PDF from the generated images
4. **Optimization**: Uses Ghostscript to optimize the final PDF file
5. **Cleanup**: Automatically removes temporary files

## Output Information

The script provides detailed information about the conversion process:

```txt
    [INFO] Converting PDF to trusted format...
    [INFO] Input: document.pdf
    [INFO] Output: document.trusted.pdf
    [INFO] DPI: 300
    [INFO] Step 1: Converting PDF pages to images...
    [INFO] Generated 15 page images
    [INFO] Step 2: Converting images back to PDF...
    [INFO] Step 3: Optimizing output PDF...
    [SUCCESS] PDF conversion completed successfully!
    [INFO] Summary:
    [INFO]   - Original file: document.pdf (2048576 bytes)
    [INFO]   - Trusted file: document.trusted.pdf (3145728 bytes)
    [INFO]   - Pages processed: 15
    [INFO]   - DPI used: 300
    [WARNING] Note: Text is now embedded as images and cannot be selected or searched.
```

## Use Cases

- **Email attachments**: Sanitize PDFs received via email
- **Downloaded documents**: Clean PDFs from untrusted sources
- **Forensic analysis**: Create safe copies of potentially malicious documents
- **Compliance**: Meet security requirements for document processing
- **Air-gapped systems**: Prepare documents for secure environments

## Performance Considerations

- **DPI vs File Size**: Higher DPI results in larger files but better quality
- **Memory Usage**: Large PDFs may require significant temporary disk space
- **Processing Time**: Conversion time scales with document size and DPI

### Recommended DPI Settings

| Use Case            | DPI     | Quality   | File Size |
| ------------------- | ------- | --------- | --------- |
| Text documents      | 150-200 | Good      | Small     |
| General use         | 300     | Excellent | Medium    |
| High-quality images | 450-600 | Premium   | Large     |

## Troubleshooting

### Common Issues

**"Command not found" errors:**

```bash
# Install missing dependencies
brew install imagemagick ghostscript
```

**"No images were generated" error:**

- The input file may be corrupted
- Try with a different PDF file
- Check if the PDF is password-protected

**Out of disk space:**

- Large PDFs generate many temporary files
- Ensure sufficient disk space in `/tmp`
- Consider using lower DPI settings

**Permission denied:**

```bash
chmod +x pdf-trusted-converter.sh
```

### Debug Mode

Use verbose mode to see detailed command execution:

```bash
./pdf-trusted-converter.sh -v document.pdf
```

## Security Considerations

This tool is designed to neutralize potentially malicious PDFs, but it should be used as part of a comprehensive security strategy:

- Always scan files with antivirus software
- Use in combination with other security tools
- Test with known-good files first
- Consider using in isolated environments for highly suspicious files

## Limitations

- Text becomes non-searchable and non-selectable
- Interactive elements are completely removed
- Some visual elements may be slightly degraded
- File sizes typically increase
- Accessibility features are lost

## Contributing

Contributions are welcome! Please feel free to submit pull requests or open issues for:

- Bug fixes
- Feature enhancements
- Documentation improvements
- Platform compatibility

## License

This project is licensed under the MIT License - see the [LICENSE](./LICENSE) file for details.

## Acknowledgments

- Inspired by Qubes OS's `qvm-convert-pdf` utility
- Built using ImageMagick and Ghostscript
- Thanks to the open-source security community

**⚠️ Important**: This tool converts text to images, making it non-selectable. Use only when security is prioritized over text accessibility.
