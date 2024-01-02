#! /bin/sh

ulimit -n 65535
rtpengine-recording --spool-dir=/usr/local/fs_record/spool --output-storage=file --output-dir=/usr/local/fs_record/wav --output-format=wav --output-mixed --pidfile=/usr/local/rtpengine/run/rtpengine-recording.pid --log-level=3 --foreground
