FROM metabase/metabase:v0.32.9

ENV FB_DRIVER_URL=https://github.com/evosec/metabase-firebird-driver/releases/download/v1.0/firebird.metabase-driver.jar \
    FB_DRIVER=firebird.metabase-driver.jar \
    PLUGINS_PATH=/plugins   

RUN wget -O ${PLUGINS_PATH}/${FB_DRIVER} ${FB_DRIVER_URL}

RUN chmod 644 ${PLUGINS_PATH}/${FB_DRIVER} 

ENTRYPOINT ["/app/run_metabase.sh"]