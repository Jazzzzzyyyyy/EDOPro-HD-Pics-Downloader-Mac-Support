#!/bin/bash

# EDOPro HD Pics Downloader for macOS
# Downloads HD images of Yu-Gi-Oh! cards for EDOPro
# Compatible with macOS directory structure

set -e  # Exit on error
set -u  # Exit on undefined variable

# ==================== Configuration ====================

API_URL="https://db.ygoprodeck.com/api/v7/cardinfo.php"
IMG_BASE_URL="https://images.ygoprodeck.com/images/cards"
MAX_CONCURRENT=20
RETRY_COUNT=3
TIMEOUT_SECONDS=30

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ==================== Directory Detection ====================

detect_edopro_directory() {
    local default_mac_path="/Applications/ProjectIgnis"
    
    # Check if running on macOS
    if [[ "$OSTYPE" != "darwin"* ]]; then
        echo -e "${YELLOW}Warning: This script is designed for macOS but can work on other Unix systems.${NC}"
    fi
    
    # Try to find EDOPro directory
    if [[ -d "$default_mac_path" ]]; then
        EDOPRO_DIR="$default_mac_path"
        echo -e "${GREEN}Found EDOPro directory: $EDOPRO_DIR${NC}"
    elif [[ -d "./pics" ]] || [[ -d "../pics" ]]; then
        # Running from within EDOPro directory
        EDOPRO_DIR="$(pwd)"
        echo -e "${GREEN}Using current directory: $EDOPRO_DIR${NC}"
    else
        # Ask user for custom path
        echo -e "${YELLOW}EDOPro directory not found at default location.${NC}"
        echo -n "Enter the path to your EDOPro installation: "
        read -r EDOPRO_DIR
        
        if [[ ! -d "$EDOPRO_DIR" ]]; then
            echo -e "${RED}Error: Directory does not exist: $EDOPRO_DIR${NC}"
            exit 1
        fi
    fi
    
    # Set target directories
    PICS_DIR="$EDOPRO_DIR/pics"
    FIELD_DIR="$PICS_DIR/field"
}

# ==================== Utility Functions ====================

log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%H:%M:%S')
    
    case "$level" in
        "INFO")
            echo -e "${BLUE}[$timestamp]${NC} $message"
            ;;
        "SUCCESS")
            echo -e "${GREEN}[$timestamp]${NC} $message"
            ;;
        "WARNING")
            echo -e "${YELLOW}[$timestamp]${NC} $message"
            ;;
        "ERROR")
            echo -e "${RED}[$timestamp]${NC} $message"
            ;;
        *)
            echo "[$timestamp] $message"
            ;;
    esac
}

ensure_directory() {
    local dir="$1"
    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir"
        log_message "INFO" "Created directory: $dir"
    fi
}

# ==================== API Functions ====================

fetch_card_data() {
    log_message "INFO" "Retrieving card data from YGOProDeck API..."
    
    local temp_file=$(mktemp)
    local http_code
    
    # Use curl to fetch data with timeout and retry
    http_code=$(curl -s -w "%{http_code}" -o "$temp_file" \
        --max-time "$TIMEOUT_SECONDS" \
        --retry "$RETRY_COUNT" \
        --retry-delay 2 \
        "$API_URL")
    
    if [[ "$http_code" != "200" ]]; then
        log_message "ERROR" "API returned HTTP status code: $http_code"
        rm -f "$temp_file"
        return 1
    fi
    
    if [[ ! -s "$temp_file" ]]; then
        log_message "ERROR" "API returned empty response"
        rm -f "$temp_file"
        return 1
    fi
    
    # Check for API error
    if grep -q '"error"' "$temp_file"; then
        log_message "ERROR" "API returned an error response"
        rm -f "$temp_file"
        return 1
    fi
    
    echo "$temp_file"
}

# ==================== Download Functions ====================

download_image() {
    local url="$1"
    local output_file="$2"
    local retries=0
    
    while [[ $retries -lt $RETRY_COUNT ]]; do
        if curl -s -f -L -o "$output_file" --max-time "$TIMEOUT_SECONDS" "$url"; then
            return 0
        else
            retries=$((retries + 1))
            if [[ $retries -lt $RETRY_COUNT ]]; then
                sleep $((retries * 1))
            fi
        fi
    done
    
    return 1
}

download_card() {
    local card_json="$1"
    local force_overwrite="$2"
    
    # Parse card data using awk for efficiency (single pass)
    local card_data=$(echo "$card_json" | awk '
        match($0, /"id":([0-9]+)/, arr) { if (!card_id) card_id = arr[1] }
        match($0, /"humanReadableCardType":"([^"]*)"/, arr) { card_type = arr[1] }
        match($0, /"image_url":"([^"]*)"/, arr) { print "URL:" arr[1] }
        match($0, /"image_url_cropped":"([^"]*)"/, arr) { cropped = arr[1] }
        END { 
            print "ID:" card_id
            print "TYPE:" card_type
            if (cropped) print "CROPPED:" cropped
        }
    ')
    
    local card_id=$(echo "$card_data" | grep "^ID:" | cut -d: -f2)
    local card_type=$(echo "$card_data" | grep "^TYPE:" | cut -d: -f2-)
    local cropped_url=$(echo "$card_data" | grep "^CROPPED:" | cut -d: -f2-)
    
    if [[ -z "$card_id" ]]; then
        return 1
    fi
    
    # Extract image URLs and IDs
    readarray -t urls_array < <(echo "$card_data" | grep "^URL:" | cut -d: -f2-)
    readarray -t ids_array < <(echo "$card_json" | grep -o '"id":[0-9]*' | sed 's/"id"://')
    
    # Download main images
    local success=0
    local skipped=0
    local idx=0
    
    for img_id in "${ids_array[@]}"; do
        [[ -z "$img_id" ]] && continue
        local output_file="$PICS_DIR/${img_id}.jpg"
        
        if [[ -f "$output_file" ]] && [[ "$force_overwrite" != "true" ]]; then
            skipped=$((skipped + 1))
        else
            if [[ $idx -lt ${#urls_array[@]} ]] && [[ -n "${urls_array[$idx]}" ]]; then
                if download_image "${urls_array[$idx]}" "$output_file"; then
                    success=$((success + 1))
                else
                    log_message "ERROR" "Failed to download image for card ID: $img_id"
                    return 1
                fi
            fi
        fi
        idx=$((idx + 1))
    done
    
    # Handle Field Spell cropped images
    if [[ "$card_type" == "Field Spell" ]] && [[ -n "$cropped_url" ]]; then
        local cropped_file="$FIELD_DIR/${card_id}.jpg"
        
        if [[ ! -f "$cropped_file" ]] || [[ "$force_overwrite" == "true" ]]; then
            if ! download_image "$cropped_url" "$cropped_file"; then
                log_message "WARNING" "Failed to download cropped image for Field Spell ID: $card_id"
            fi
        fi
    fi
    
    if [[ $skipped -gt 0 ]]; then
        echo "SKIPPED"
    elif [[ $success -gt 0 ]]; then
        echo "SUCCESS"
    else
        echo "ERROR"
    fi
}

# ==================== Main Download Logic ====================

process_downloads() {
    local data_file="$1"
    local force_overwrite="$2"
    
    # Extract card data array
    log_message "INFO" "Parsing card data..."
    
    # Use jq if available, otherwise use grep/sed
    if command -v jq &> /dev/null; then
        local total_cards=$(jq '.data | length' "$data_file")
        log_message "SUCCESS" "Successfully retrieved $total_cards card IDs"
        
        # Process downloads with progress tracking
        local processed=0
        local skipped=0
        local errors=0
        local success=0
        
        # Create temporary directory for parallel processing
        local temp_dir=$(mktemp -d)
        local max_jobs=$MAX_CONCURRENT
        
        log_message "INFO" "Starting download with $max_jobs concurrent connections..."
        
        # Process each card using process substitution to avoid subshell issues
        while read -r card; do
            # Wait if we have too many background jobs
            while [[ $(jobs -r | wc -l) -ge $max_jobs ]]; do
                sleep 0.1
            done
            
            (
                result=$(download_card "$card" "$force_overwrite")
                echo "$result" >> "$temp_dir/results.txt"
            ) &
        done < <(jq -c '.data[]' "$data_file")
        
        # Wait for all background jobs to complete
        wait
        
        # Count results
        if [[ -f "$temp_dir/results.txt" ]]; then
            success=$(grep -c "SUCCESS" "$temp_dir/results.txt" 2>/dev/null || echo 0)
            skipped=$(grep -c "SKIPPED" "$temp_dir/results.txt" 2>/dev/null || echo 0)
            errors=$(grep -c "ERROR" "$temp_dir/results.txt" 2>/dev/null || echo 0)
            processed=$((success + skipped + errors))
        fi
        
        # Clean up
        rm -rf "$temp_dir"
        
        log_message "SUCCESS" "Download completed!"
        log_message "INFO" "Total: $total_cards | Processed: $processed | Skipped: $skipped | Errors: $errors"
        
    else
        # Fallback without jq (less efficient but functional)
        log_message "WARNING" "jq not found. Using fallback parser (slower)."
        log_message "INFO" "For better performance, install jq: brew install jq"
        
        # Create temporary directory for results
        local temp_dir=$(mktemp -d)
        local max_jobs=$MAX_CONCURRENT
        
        # Extract card IDs manually
        local -a card_ids=()
        while IFS= read -r id; do
            [[ -n "$id" ]] && card_ids+=("$id")
        done < <(grep -o '"id":[0-9]*' "$data_file" | sed 's/"id"://' | sort -u)
        
        local total_cards=${#card_ids[@]}
        log_message "SUCCESS" "Successfully retrieved $total_cards unique card IDs"
        log_message "INFO" "Starting download with $max_jobs concurrent connections..."
        
        # Download each card
        for card_id in "${card_ids[@]}"; do
            # Wait if we have too many background jobs
            while [[ $(jobs -r | wc -l) -ge $max_jobs ]]; do
                sleep 0.1
            done
            
            (
                # Extract card data for this ID from the JSON
                local card_json=$(awk -v id="$card_id" '
                    /"id":'"$card_id"'[^0-9]/ {in_card=1; card=""}
                    in_card {card=card $0}
                    in_card && /}[,\]]/ {print card; in_card=0}
                ' "$data_file")
                
                if [[ -n "$card_json" ]]; then
                    result=$(download_card "$card_json" "$force_overwrite")
                    echo "$result" >> "$temp_dir/results.txt"
                fi
            ) &
        done
        
        # Wait for all background jobs to complete
        wait
        
        # Count results
        local success=0
        local skipped=0
        local errors=0
        local processed=0
        
        if [[ -f "$temp_dir/results.txt" ]]; then
            success=$(grep -c "SUCCESS" "$temp_dir/results.txt" 2>/dev/null || echo 0)
            skipped=$(grep -c "SKIPPED" "$temp_dir/results.txt" 2>/dev/null || echo 0)
            errors=$(grep -c "ERROR" "$temp_dir/results.txt" 2>/dev/null || echo 0)
            processed=$((success + skipped + errors))
        fi
        
        # Clean up
        rm -rf "$temp_dir"
        
        log_message "SUCCESS" "Download completed!"
        log_message "INFO" "Total: $total_cards | Processed: $processed | Skipped: $skipped | Errors: $errors"
    fi
}

# ==================== GUI Option (Optional) ====================

show_gui_prompt() {
    if command -v osascript &> /dev/null; then
        # macOS AppleScript dialog
        local choice=$(osascript 2>/dev/null <<EOF
tell application "System Events"
    activate
    set theChoice to button returned of (display dialog "EDOPro HD Pics Downloader

Would you like to:
• Download all cards
• Force overwrite existing images

Choose an option:" buttons {"Cancel", "Download", "Force Overwrite"} default button "Download")
end tell
return theChoice
EOF
)
        echo "$choice"
    else
        echo ""
    fi
}

# ==================== Main Script ====================

main() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}EDOPro HD Pics Downloader for macOS${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    
    # Check for GUI mode
    local force_overwrite="false"
    local gui_mode="false"
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -f|--force)
                force_overwrite="true"
                shift
                ;;
            -g|--gui)
                gui_mode="true"
                shift
                ;;
            -h|--help)
                echo "Usage: $0 [OPTIONS]"
                echo ""
                echo "Options:"
                echo "  -f, --force    Force overwrite existing images"
                echo "  -g, --gui      Show GUI prompt (macOS only)"
                echo "  -h, --help     Show this help message"
                echo ""
                exit 0
                ;;
            *)
                echo -e "${RED}Unknown option: $1${NC}"
                exit 1
                ;;
        esac
    done
    
    # Show GUI if requested
    if [[ "$gui_mode" == "true" ]]; then
        local gui_choice=$(show_gui_prompt)
        case "$gui_choice" in
            "Force Overwrite")
                force_overwrite="true"
                ;;
            "Cancel")
                log_message "INFO" "Operation cancelled by user"
                exit 0
                ;;
        esac
    fi
    
    # Detect EDOPro directory
    detect_edopro_directory
    
    # Ensure directories exist
    ensure_directory "$PICS_DIR"
    ensure_directory "$FIELD_DIR"
    
    # Fetch card data
    local data_file=$(fetch_card_data)
    
    if [[ -z "$data_file" ]] || [[ ! -f "$data_file" ]]; then
        log_message "ERROR" "Failed to retrieve card data from API"
        exit 1
    fi
    
    # Show configuration
    log_message "INFO" "Configuration:"
    log_message "INFO" "  - Target directory: $PICS_DIR"
    log_message "INFO" "  - Force overwrite: $force_overwrite"
    log_message "INFO" "  - Max concurrent downloads: $MAX_CONCURRENT"
    echo ""
    
    # Process downloads
    process_downloads "$data_file" "$force_overwrite"
    
    # Clean up
    rm -f "$data_file"
    
    echo ""
    log_message "SUCCESS" "All done! Your EDOPro pics directory has been updated."
    
    # Show GUI completion message if in GUI mode
    if [[ "$gui_mode" == "true" ]] && command -v osascript &> /dev/null; then
        osascript -e 'display notification "All card images have been downloaded successfully!" with title "EDOPro HD Pics Downloader" sound name "Glass"' 2>/dev/null || true
    fi
}

# Run main function
main "$@"
