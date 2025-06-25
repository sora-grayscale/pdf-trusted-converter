#!/bin/bash

# PDF Trusted Converter for macOS
# Similar to Qubes OS qvm-convert-pdf functionality
# Converts PDF to images and back to PDF to remove potential threats

set -e

# Configuration
DPI=300
TEMP_DIR=$(mktemp -d)
SCRIPT_NAME=$(basename "$0")

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to show usage
show_usage() {
    cat << EOF
Usage: $SCRIPT_NAME [OPTIONS] <input.pdf> [output.pdf]

Convert PDF to trusted format by converting to images and back to PDF.
This removes JavaScript, forms, links, and other potentially dangerous elements.

OPTIONS:
    -d, --dpi DPI       Set DPI for conversion (default: 300)
    -b, --batch         Batch mode: overwrite original file with .trusted suffix
    -h, --help          Show this help message
    -v, --verbose       Verbose output

EXAMPLES:
    $SCRIPT_NAME document.pdf trusted_document.pdf
    $SCRIPT_NAME --batch document.pdf
    $SCRIPT_NAME -d 600 high_quality.pdf output.pdf

REQUIREMENTS:
    - ImageMagick (brew install imagemagick)
    - Ghostscript (brew install ghostscript)
EOF
}

# Function to check dependencies
check_dependencies() {
    local missing_deps=()
    
    if ! command -v convert &> /dev/null; then
        missing_deps+=("imagemagick")
    fi
    
    if ! command -v gs &> /dev/null; then
        missing_deps+=("ghostscript")
    fi
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        print_error "Missing dependencies: ${missing_deps[*]}"
        print_error "Install with: brew install ${missing_deps[*]}"
        exit 1
    fi
}

# Function to cleanup temporary files
cleanup() {
    if [ -d "$TEMP_DIR" ]; then
        rm -rf "$TEMP_DIR"
    fi
}

# Set trap to cleanup on exit
trap cleanup EXIT

# Function to convert PDF to trusted format
convert_pdf_to_trusted() {
    local input_pdf="$1"
    local output_pdf="$2"
    local verbose="$3"
    
    # Check if input file exists
    if [ ! -f "$input_pdf" ]; then
        print_error "Input file does not exist: $input_pdf"
        return 1
    fi
    
    # Check if input is actually a PDF
    if ! file "$input_pdf" | grep -q "PDF"; then
        print_error "Input file is not a PDF: $input_pdf"
        return 1
    fi
    
    print_status "Converting PDF to trusted format..."
    print_status "Input: $input_pdf"
    print_status "Output: $output_pdf"
    print_status "DPI: $DPI"
    
    # Get file size before conversion
    local input_size=$(stat -f%z "$input_pdf" 2>/dev/null || echo "unknown")
    
    # Step 1: Convert PDF pages to PNG images
    print_status "Step 1: Converting PDF pages to images..."
    local convert_cmd="convert -density $DPI \"$input_pdf\" \"$TEMP_DIR/page-%03d.png\""
    
    if [ "$verbose" = "true" ]; then
        print_status "Running: $convert_cmd"
    fi
    
    if ! eval "$convert_cmd" 2>/dev/null; then
        print_error "Failed to convert PDF to images"
        return 1
    fi
    
    # Count generated images
    local image_count=$(ls -1 "$TEMP_DIR"/page-*.png 2>/dev/null | wc -l)
    print_status "Generated $image_count page images"
    
    if [ "$image_count" -eq 0 ]; then
        print_error "No images were generated from PDF"
        return 1
    fi
    
    # Step 2: Convert images back to PDF
    print_status "Step 2: Converting images back to PDF..."
    local img2pdf_cmd="convert \"$TEMP_DIR/page-*.png\" \"$output_pdf\""
    
    if [ "$verbose" = "true" ]; then
        print_status "Running: $img2pdf_cmd"
    fi
    
    if ! eval "$img2pdf_cmd" 2>/dev/null; then
        print_error "Failed to convert images back to PDF"
        return 1
    fi
    
    # Step 3: Optimize the output PDF
    print_status "Step 3: Optimizing output PDF..."
    local temp_optimized="$TEMP_DIR/optimized.pdf"
    local gs_cmd="gs -dNOPAUSE -dBATCH -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dPDFSETTINGS=/default -sOutputFile=\"$temp_optimized\" \"$output_pdf\""
    
    if [ "$verbose" = "true" ]; then
        print_status "Running: $gs_cmd"
    fi
    
    if eval "$gs_cmd" >/dev/null 2>&1; then
        mv "$temp_optimized" "$output_pdf"
        print_status "PDF optimization completed"
    else
        print_warning "PDF optimization failed, keeping unoptimized version"
    fi
    
    # Get output file size
    local output_size=$(stat -f%z "$output_pdf" 2>/dev/null || echo "unknown")
    
    # Show conversion summary
    print_success "PDF conversion completed successfully!"
    print_status "Summary:"
    print_status "  - Original file: $input_pdf ($input_size bytes)"
    print_status "  - Trusted file: $output_pdf ($output_size bytes)"
    print_status "  - Pages processed: $image_count"
    print_status "  - DPI used: $DPI"
    
    print_warning "Note: Text is now embedded as images and cannot be selected or searched."
}

# Parse command line arguments
BATCH_MODE=false
VERBOSE=false
INPUT_PDF=""
OUTPUT_PDF=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--dpi)
            DPI="$2"
            shift 2
            ;;
        -b|--batch)
            BATCH_MODE=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        -*)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
        *)
            if [ -z "$INPUT_PDF" ]; then
                INPUT_PDF="$1"
            elif [ -z "$OUTPUT_PDF" ]; then
                OUTPUT_PDF="$1"
            else
                print_error "Too many arguments"
                show_usage
                exit 1
            fi
            shift
            ;;
    esac
done

# Validate DPI
if ! [[ "$DPI" =~ ^[0-9]+$ ]] || [ "$DPI" -lt 72 ] || [ "$DPI" -gt 600 ]; then
    print_error "DPI must be a number between 72 and 600"
    exit 1
fi

# Check if input file is provided
if [ -z "$INPUT_PDF" ]; then
    print_error "Input PDF file is required"
    show_usage
    exit 1
fi

# Set output filename
if [ "$BATCH_MODE" = "true" ]; then
    # In batch mode, create output with .trusted suffix
    OUTPUT_PDF="${INPUT_PDF%.*}.trusted.pdf"
elif [ -z "$OUTPUT_PDF" ]; then
    # If no output specified, use input name with .trusted suffix
    OUTPUT_PDF="${INPUT_PDF%.*}.trusted.pdf"
fi

# Check if output file already exists
if [ -f "$OUTPUT_PDF" ]; then
    read -p "Output file already exists. Overwrite? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Operation cancelled by user"
        exit 0
    fi
fi

# Check dependencies
check_dependencies

# Convert PDF
convert_pdf_to_trusted "$INPUT_PDF" "$OUTPUT_PDF" "$VERBOSE"