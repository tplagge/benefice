# format [name, domain, data_type, socrata_id, options]

datasets_core = [
 # pg_dumps from Cory's scrapers - disabled for now
 # see https://github.com/maschinenmensch/edifice/issues/21
 # ['cook_county','','pgdump','',{}],
 # ['assessor','','pgdump','',{}],
 # ['landuse','','pgdump','',{}],

 # gazeeter for address matching
 # see: https://github.com/maschinenmensch/edifice/issues/23
 ['street_gazetteer','Chicago','csv','i6bp-fvbx',{}],
 ['street_centerlines','Chicago','shp','xy4z-b6aa',{}],

 # core buildings datasets
 ['building_footprints','Chicago','shp','w2v3-isjw',{'encoding': 'LATIN1'}],
 ['building_permits','Chicago','csv','ydr8-5enu',{}],
 ['building_violations','Chicago','csv','22u3-xenr',{}],
 ['zoning_aug2012','Chicago','shp','p8va-airx',{}]
]
