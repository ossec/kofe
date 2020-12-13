# KOFE
KOFE is an opensource, SIEM-like experience powered by Kibana, OSSEC
Filebeat, and Elasticsearch

Installing
==========
1) Add the Atomic Repository

    wget -q -O - https://updates.atomicorp.com/installers/atomic |bash


2) Install OUM (OSSEC Updater Modified)

    yum install oum


3) Install KOFE via OUM


    oum install kofe


4) Run KOFE setup to begin configuration

    kofe setup

Dashboards
==========
KOFE comes with a suite of dashboards provided by Atomicorp.

1) Installing a dashboard

    kofe install <dashboard nam> 


2) Listing a dashboard

    kofe list
