# certs_updater

* certs.csv: [name, cert, date, advancedFlag] Our consultants' certs
* consultants.csv: [name] Our consultants. name is firstname lastname
* sf.csv: [name, cert, date, advancedFlag] Salesforce’s record of our consultants' certs
* update_certs.csv is output: ["Name", "Certificate", "Date", "Advanced", "In Master", "Debut", "New Cert"]

New Cert values:
* contingent: found in certs but not in sf;
* new: found in sf but not in certs;
* confirmed: same cert and date found in sf and certs,
* updated: same cert and later date found in sf
* older: same cert but earlier date in sf
