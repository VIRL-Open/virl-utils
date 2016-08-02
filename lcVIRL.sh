#! /bin/sh
#
# Live packet capture from VIRL
#

VERSION="0.1"


while getopts ":hvp:cw" opt; do
  case $opt in
    h)
      echo "usage: $(basename "$0") [-h] [-v] [-c | -w] -p PORT [Virl_IP]"
      echo "Options:"
      echo "  -h   ---   Show this help message"
      echo "  -v   ---   Show Version number"
      echo "  -c   ---   Create pipe file to be listen on"
      echo "  -w   ---   Capture packets with wireshark"
      echo "  -p   ---   Specify port to capture packets"
      echo "  Virl_IP    VIRL mgmt ip address"
      echo ""
      echo "-----------"
      echo "  Virl_IP is only optional if VIRL_HOST env variable is set!"
      echo ""
      exit 0
      ;;
    v)
      echo "Version: $VERSION"
      exit 0
      ;;
    p)
      PORT=$OPTARG
      ;;
    c)
      PIPE_USE=1
      ;;
    w)
      WIRESHARK_USE=1
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
    *)
      echo "Unimplemented option: -$OPTARG" >&2
      exit 1
      ;;
  esac
done

shift $((OPTIND-1))


# Check VIRL_HOST environment variable
if [ -z "$VIRL_HOST" ]; then
  if [ -z "$1" ]; then
    echo "Virl mgmt ip address must be set" >&2
    exit 1
  else
    HOST=$1
  fi
else
  HOST=$VIRL_HOST
fi


# PORT is mandatory!
if [ -z "$PORT" ]; then
  echo "Port parameter must be set" >&2
  exit 1
fi


# Verify that both WIRESHARK_USE and PIPE_USE aren't set at the same time
if [ -n "$WIRESHARK_USE" ] && [ -n "$PIPE_USE" ]; then
  echo "Can't set both flags [-w and -c] at the same time."
  exit 1
fi


# Verify that at least WIRESHARK_USE or PIPE_USE are set
if [ -z "$WIRESHARK_USE" ] && [ -z "$PIPE_USE" ]; then
  echo "Need to set one of these flags -w or -c"
  exit 1
fi


# Use wireshark
if [ -n "$WIRESHARK_USE" ] && [ "$WIRESHARK_USE" -eq 1 ]; then
    nc $HOST $PORT | wireshark -ki -
fi


# Open pipe file
if [ -n "$PIPE_USE" ] && [ "$PIPE_USE" -eq 1 ]; then
  PIPE=/tmp/lcvirl
  printf -v PIPE_NAME "%s_%s_%s" $PIPE $PORT $RANDOM

  if [[ ! -p $PIPE_NAME ]]; then
    mkfifo $PIPE_NAME
  fi

  echo "Pipe: $PIPE_NAME"

  # Capture sigTerm [Ctrl-C]
  trap "echo -e '\n==> Removing Pipe'; rm $PIPE_NAME" SIGINT SIGTERM

  command -v xclip > /dev/null 2>&1
  if [ "$?" -eq "0" ]; then
    echo $PIPE_NAME | xclip -selection c
    echo "==> Pipe filename copied to clipboard."
  else
    echo "==> warning: xclip not found. Please consider installing it."
  fi

  nc $HOST $PORT > $PIPE_NAME
fi
