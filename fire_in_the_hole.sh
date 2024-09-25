# Check if the script is being run as root
check_privileges() {
  if [ "$EUID" -ne 0 ]; then
    echo "\e[31mThis script requires sudo privileges. Please run it as root or with sudo.\e[0m"
    exit 1
  fi
}
# Function to parse the argument
parse_args() {
  if [ $# -eq 0 ]; then
    interactive=false
  else
  interactive=true
    for arg in "$@"; do
        case $arg in
            --interactive=*)
                # Extract the value after '='
                interactive_mode="${arg#*=}"
                ;;
            --interactive)
                # If no value is specified, use the default "cli"
                interactive_mode="cli"
                ;;
            *)
                echo -e "\e[31mUnknown argument:\e[0m $arg"
                exit 1
                ;;
        esac
    done
}

setup_essentials()

check_privileges
parse_args "$@"

