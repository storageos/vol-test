[SERVICE]
    Flush        5
    Daemon       Off
    Log_Level    info
    Parsers_File parsers.conf

[INPUT]
    Name systemd
    Tag  host.*

[INPUT]
    Name   forward
    Listen 0.0.0.0
    Port   24224    

[OUTPUT]
    Name            es
    Match           *
    Host            ${es_host}
    Port            ${es_port}
    HTTP_User       ${es_user}
    HTTP_Passwd     ${es_pass}
    Type            fluent
    Logstash_Format On
    Logstash_Prefix logstash
    Time_Key        @timestamp
    Retry_Limit     False
    Tag_Key         tag

[FILTER]
    Name record_modifier
    Match *
    record host $${HOSTNAME}
