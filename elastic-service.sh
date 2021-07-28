#!/bin/sh
### sudo curl -s https://raw.githubusercontent.com/apinizer/apinizer/main/installApinizer.sh | bash
SERVICE_NAME=elasticsearch
PATH_TO_APP="/opt/elasticsearch/elasticsearch-7.9.2/bin/$SERVICE_NAME"
PID_PATH_NAME="/opt/elasticsearch/elasticsearch-7.9.2/bin/$SERVICE_NAME.pid"
SCRIPTNAME=elasticsearch-service.sh
ES_USER=$SERVICE_NAME
ES_GROUP=$SERVICE_NAME
 
case $1 in
    start)
        echo "Starting $SERVICE_NAME ..."
        if [ ! -f $PID_PATH_NAME ]; then
        mkdir $(dirname $PID_PATH_NAME) > /dev/null 2>&1 || true
            chown $ES_USER $(dirname $PID_PATH_NAME)
            $SUDO $PATH_TO_APP -d -p $PID_PATH_NAME
        echo "Return code: $?"
            echo "$SERVICE_NAME started ..."
        else
            echo "$SERVICE_NAME is already running ..."
        fi
    ;;
    stop)
        if [ -f $PID_PATH_NAME ]; then
            PID=$(cat $PID_PATH_NAME);
            echo "$SERVICE_NAME stopping ..."
            kill -15 $PID;
            echo "$SERVICE_NAME stopped ..."
            rm $PID_PATH_NAME
        else
            echo "$SERVICE_NAME is not running ..."
        fi
    ;;
    restart)
        if [ -f $PID_PATH_NAME ]; then
            PID=$(cat $PID_PATH_NAME);
            echo "$SERVICE_NAME stopping ...";
            kill -15 $PID;
        sleep 1;
            echo "$SERVICE_NAME stopped ...";
            rm -rf $PID_PATH_NAME
            echo "$SERVICE_NAME starting ..."
            mkdir $(dirname $PID_PATH_NAME) > /dev/null 2>&1 || true
            chown $ES_USER $(dirname $PID_PATH_NAME)
            $SUDO $PATH_TO_APP -d -p $PID_PATH_NAME
            echo "$SERVICE_NAME started ..."
         else
            echo "$SERVICE_NAME is not running ..."
        fi
    ;;
  *)
    echo "Usage: $SCRIPTNAME {start|stop|restart}" >&2
    exit 3
    ;;
esac
