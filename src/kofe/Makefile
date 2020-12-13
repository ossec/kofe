srcdir = .
current_dir = $(shell pwd)
usr_dir = $(PREFIX)/usr
bin_dir = $(PREFIX)/usr/bin
share_dir = $(PREFIX)/usr/share
filebeat_dir = $(PREFIX)/usr/share/kofe/filebeat
dashboard_dir = $(PREFIX)/usr/share/kofe/dashboards


install:
	mkdir -p "$(usr_dir)/"
	mkdir -p "$(bin_dir)/"
	mkdir -p "$(share_dir)/kofe/"
	mkdir -p "$(share_dir)/kofe/bin/"
	mkdir -p "$(filebeat_dir)/module"
	mkdir -p "$(dashboard_dir)/"
	install -Dp -m 755 bin/kofe.sh "$(bin_dir)/kofe"
	install -Dp -m 644 conf/*.conf "$(share_dir)/kofe"
	install -Dp -m 644 templates/template.json "$(share_dir)/kofe"
	cp -a filebeat-connector/ossec "$(filebeat_dir)/module"
	cp -a filebeat-connector/filebeat.yml.template "$(filebeat_dir)/"
	cp -a filebeat-connector/ossec-template.json "$(filebeat_dir)/"
	cp -a dashboards/*.ndjson "$(dashboard_dir)/"
