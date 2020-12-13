Summary: Kibana OSSEC Filebeat Elasticsearch
Name:    kofe
Version: 1.2.0
Release: RELEASE-AUTO%{?dist}.art
Source0: kofe.tar.gz
Requires: kofe-dashboards

License: AGPL
URL: http://www.atomicorp.com
Group: Application/Internet
Vendor: Atomicorp
Packager: Scott R. Shinn <scott@atomicorp.com>
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root
Prefix: %{_prefix}

%description
KOFE (Kibana OSSEC Filebeat Elasticsearch) is an OSSEC server console
based on Elasticsearch, Filebeat, and Kibana.


%package dashboards
Summary: KOFE Dashboards provided by Atomicorp.
Group: System/Servers
Requires: kofe

%description dashboards
KOFE (Kibana OSSEC Filebeat ELasticsearch) Dashboards provided
by Atomicorp.


%prep

%setup -n kofe

%build

%install
[ -n "${RPM_BUILD_ROOT}" -a "${RPM_BUILD_ROOT}" != "/" ] && rm -rf ${RPM_BUILD_ROOT}
%{__make} install PREFIX="%{buildroot}"





%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root,-)
/usr/bin/kofe
/usr/share/kofe/listen.conf
/usr/share/kofe/local.conf
/usr/share/kofe/template.json
/usr/share/kofe/filebeat/*

%files dashboards
/usr/share/kofe/dashboards/*

%changelog
* Fri Oct 30 2020 Cody Woods - 1.2
- Changes package name to KOFE. Now new name of this package.

* Mon Jul 20 2020 Scott R. Shinn <scott@atomicorp.com> - 1.1
- Adding templates and minor fixes to setup

* Thu May 23 2019 Scott R. Shinn <scott@atomicorp.com> - 1.0
- Adding remote/local dialog, user creation, and more

* Tue May 3 2016 Scott R. Shinn <scott@atomicorp.com> - 0.1-1
- Initialize
