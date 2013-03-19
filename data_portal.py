# Functions for importing shapefiles and CSV files from Socrata (as imported into tables in the schema 'dataportal')
# into the custom tables in the Benefice database. For example, the 'building_footprints' data (geometry and table)
# is used to populate buildings.buildings, buildings.buildings_address, buildings.sqft, buildings.year_built,
# buildings.buildings_bldg_name and possibly more.

def execute_and_print(cur, sql):
    print sql
    cur.execute(sql)

# do_buildingfootprints()
# This adds rows for the following tables/columns):
#    buildings.buildings(bldg_gid, the_geom) [still need centroid]
#    buildings.address (bldg_gid, f_add1, t_add1, pre_dir1, st_name1, st_type1)
#    buildings.bldg_name (bldg_gid, name, name2)
#    buildings.sqft(bldg_gid, sqft)
def do_buildingfootprints(db_conn):
    
    cur=db_conn.cursor()

    # deleting rows from existing tables (if any), going through tables in reverse order

    execute_and_print(cur, "DELETE FROM buildings.year_built")
    execute_and_print(cur, "DELETE FROM buildings.sqft")
    execute_and_print(cur, "DELETE FROM buildings.buildings_bldg_name")
    execute_and_print(cur, "DELETE FROM buildings.address")
    execute_and_print(cur, "DELETE FROM buildings.buildings")
    execute_and_print(cur, "INSERT INTO buildings.buildings(bldg_gid,the_geom) SELECT gid, the_geom FROM dataportal.building_footprints")

    # XXX: What about buildings.buildings.centroid? How do we compute that?

    execute_and_print(cur, "INSERT INTO buildings.address (bldg_gid, f_add1, t_add1, pre_dir1, st_name1, st_type1) SELECT gid, f_add1, t_add1, pre_dir1, st_name1, st_type1 FROM dataportal.building_footprints WHERE st_name1 is NOT NULL")

    # XXX: is it important to loop through f_add1 to t_add1, adding
    # buildings.alternate_addresses for each interpolated address? Or do we get that info elsewhere?
    
    execute_and_print(cur, "INSERT INTO buildings.buildings_bldg_name(bldg_gid, name, name2) SELECT gid, bldg_name1, bldg_name2 FROM dataportal.building_footprints WHERE bldg_name1 IS NOT NULL")
    execute_and_print(cur, "INSERT INTO buildings.sqft(bldg_gid, sqft) SELECT gid, bldg_sq_fo FROM dataportal.building_footprints where bldg_sq_fo != 0")
    execute_and_print(cur, "INSERT INTO buildings.year_built(bldg_gid, year_built) SELECT gid, year_built FROM dataportal.building_footprints where year_built != 0")

    # XXX: seems like dataportal.building_footprints.no_stories does not have useful stuff in it
    #sql = "INSERT INTO buildings.stories (bldg_gid, stories) SELECT gid, no_stories FROM dataportal.building_footprints

def do_import(name, db_conn):
    if (name == 'building_footprints'):
        do_buildingfootprints(db_conn)
    else:
        print "data portal import for '%s' not implemented yet. Sorry!" % name
