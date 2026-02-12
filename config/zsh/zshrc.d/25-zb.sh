# All of these are added by zerobrew

export ZEROBREW_DIR=~/.zerobrew
export ZEROBREW_BIN=~/.zerobrew/bin
export ZEROBREW_ROOT=/opt/zerobrew
export ZEROBREW_PREFIX=/opt/zerobrew/prefix
export PKG_CONFIG_PATH="$ZEROBREW_PREFIX/lib/pkgconfig:${PKG_CONFIG_PATH:-}"

# SSL/TLS certificates (only if ca-certificates is installed)
if [ -f "$ZEROBREW_PREFIX/opt/ca-certificates/share/ca-certificates/cacert.pem" ]; then
  export CURL_CA_BUNDLE="$ZEROBREW_PREFIX/opt/ca-certificates/share/ca-certificates/cacert.pem"
  export SSL_CERT_FILE="$ZEROBREW_PREFIX/opt/ca-certificates/share/ca-certificates/cacert.pem"
elif [ -f "$ZEROBREW_PREFIX/etc/ca-certificates/cacert.pem" ]; then
  export CURL_CA_BUNDLE="$ZEROBREW_PREFIX/etc/ca-certificates/cacert.pem"
  export SSL_CERT_FILE="$ZEROBREW_PREFIX/etc/ca-certificates/cacert.pem"
elif [ -f "$ZEROBREW_PREFIX/share/ca-certificates/cacert.pem" ]; then
  export CURL_CA_BUNDLE="$ZEROBREW_PREFIX/share/ca-certificates/cacert.pem"
  export SSL_CERT_FILE="$ZEROBREW_PREFIX/share/ca-certificates/cacert.pem"
fi

if [ -d "$ZEROBREW_PREFIX/etc/ca-certificates" ]; then
  export SSL_CERT_DIR="$ZEROBREW_PREFIX/etc/ca-certificates"
elif [ -d "$ZEROBREW_PREFIX/share/ca-certificates" ]; then
  export SSL_CERT_DIR="$ZEROBREW_PREFIX/share/ca-certificates"
fi

# Helper function to safely append to PATH
_zb_path_append() {
    local argpath="$1"
    case ":${PATH}:" in
        *:"$argpath":*) ;;
        *) export PATH="$argpath:$PATH" ;;
    esac;
}

_zb_path_append "$ZEROBREW_BIN"
_zb_path_append "$ZEROBREW_PREFIX/bin"
