# edifice

A database of the built environment in Chicago using open data

## Requirements

* PostGIS
* Python
* wget
* unzip

## Data Sources

### Buildings
* buildings, buildings_bldg_name, buildings_nonstandard, cbd_bldg_names, address, year_built, sqft, stories, university_bldg_names, ohare_bldg_names: https://data.cityofchicago.org/Buildings/Building-Footprints/w2v3-isjw
* curbs : https://data.cityofchicago.org/Transportation/Boundaries-Curb-Lines/5gv8-ktcg
* building_permits_pruned: https://data.cityofchicago.org/Buildings/Building-Permits/ydr8-5enu
* building_violations_pruned: https://data.cityofchicago.org/Buildings/Building-Violations/22u3-xenr

### Boundaries
* census_block_groups: Census.gov
* census_blocks: https://data.cityofchicago.org/Facilities-Geographic-Boundaries/Boundaries-Census-Blocks-2010/3jmu-7ijz
* census_tracts: https://data.cityofchicago.org/Facilities-Geographic-Boundaries/Boundaries-Census-Tracts-2010/biqm-wjk3
* central_business_district: https://data.cityofchicago.org/Facilities-Geographic-Boundaries/Boundaries-Central-Business-District/uagp-hcv5
* city_boundary: https://data.cityofchicago.org/Facilities-Geographic-Boundaries/Boundaries-City/q38j-zgre
* comm_areas : https://data.cityofchicago.org/Facilities-Geographic-Boundaries/Boundaries-Community-Areas/i65m-w5fr
* congress : 
* conservation boundaries : https://data.cityofchicago.org/Environment-Sustainable-Development/Boundaries-Conservation-Areas/a9rt-upwk
* empowerment_zones : https://data.cityofchicago.org/Community-Economic-Development/Boundaries-Empowerment-Zones/m6ef-sjkj
* enterpise_community : https://data.cityofchicago.org/Community-Economic-Development/Boundaries-Enterprise-Communities/fuz2-7vqu
* enterprise_zones : https://data.cityofchicago.org/Community-Economic-Development/Boundaries-Enterprise-Zones/v3uj-hd3x
* ilhouse2000 : https://data.cityofchicago.org/Facilities-Geographic-Boundaries/Boundaries-State-Congressional-Districts-House-/gpzv-tfuc
* ilsenate2000 : https://data.cityofchicago.org/Facilities-Geographic-Boundaries/Boundaries-State-Congressional-Districts-Senate-/3zsw-bmta
* industrial_corridors : https://data.cityofchicago.org/Community-Economic-Development/Boundaries-Industrial-Corridors/vdsr-p25b 
* neighborhoods : https://data.cityofchicago.org/Facilities-Geographic-Boundaries/Boundaries-Neighborhoods/9wp7-iasj
* new_wards : http://www.wbez.org/no-sidebar/approved-ward-map-95662
* planning_district : https://data.cityofchicago.org/Community-Economic-Development/Boundaries-Planning-Districts/5xt8-wz7f
* planning_region : https://data.cityofchicago.org/Community-Economic-Development/Boundaries-Planning-Regions/tcpk-wbgm
* police_districts : https://data.cityofchicago.org/Public-Safety/Boundaries-Police-Districts/4dt9-88ua
* precincts : https://data.cityofchicago.org/Facilities-Geographic-Boundaries/Ward-Precincts/sgsc-bb4n
* snow_parking : https://data.cityofchicago.org/Transportation/Snow-Route-Parking-Restrictions/i9q6-fx2v'
* special_service_area : https://data.cityofchicago.org/Community-Economic-Development/Boundaries-Special-Service-Areas/dbvs-iaa4
* sweeping : https://data.cityofchicago.org/Sanitation/Street-Sweeping/9rhq-32up
* wards : https://data.cityofchicago.org/Facilities-Geographic-Boundaries/Boundaries-Wards/bhcv-wqkf
* winterovernightparkingrestrictions : https://data.cityofchicago.org/Transportation/Winter-Overnight-Parking-Restrictions/kpim-yiyf
* zip_codes : https://data.cityofchicago.org/Facilities-Geographic-Boundaries/Boundaries-ZIP-Codes/2ka6-iycf
* zoning_aug2012 : https://data.cityofchicago.org/Community-Economic-Development/Boundaries-Zoning-Districts/p8va-airx

### Businesses
* business_licenses : https://data.cityofchicago.org/Community-Economic-Development/Business-Licenses/r5kz-chrr
* business_owners : https://data.cityofchicago.org/Community-Economic-Development/Business-Owners/ezma-pppn

### Civic
* cemeteries : https://data.cityofchicago.org/Facilities-Geographic-Boundaries/Cook-County-Cemeteries-KML/zu2x-8zyf
* chi_idhs_offices : 
* circuit_court_cook_cnty_judges  :
* community_centers :
* contracts, contracts_approval_date, contracts_city_depts, contracts_contract_type, contracts_descriptions, contracts_end_date, contracts_proc_type, contracts_spec_num, contracts_start_date, contracts_vendors : https://data.cityofchicago.org/Administration-Finance/Contracts/rsxa-ify5
* cook_co_facilities_in_chicago : https://data.cityofchicago.org/Facilities-Geographic-Boundaries/Cook-County-Facilities/wse8-j3xr
* elevation_benchmarks : https://data.cityofchicago.org/Buildings/Elevation-Benchmarks/zgvr-7yfd
* ewaste_collection_sites : 
* lobbyist_2011_agency_report : 
* lobbyist_2011_compensation :
* lobbyist_2011_major_expenditures :
* public_plazas : https://data.cityofchicago.org/Environment-Sustainable-Development/Open-Spaces-Malls-and-Plazas/ixxk-b6xq
* public_tech_resources : https://data.cityofchicago.org/Facilities-Geographic-Boundaries/Public-Technology-Resources/nen3-vcxj
* senior_centers : https://data.cityofchicago.org/Health-Human-Services/Senior-Centers/qhfc-4cw2
* youth_centers : https://data.cityofchicago.org/Health-Human-Services/Youth-Centers/meks-hp6f

### Tax Increment Financing (TIF)
* sbif_grant_agreements   : https://data.cityofchicago.org/Community-Economic-Development/Small-Business-Improvement-Fund-SBIF-Grant-Agreeme/jp7n-tgmf
* tif_balance_sheets      : https://data.cityofchicago.org/Community-Economic-Development/TIF-Balance-Sheets/hezc-e4be
* tif_balance_sheets_expenditures       :  https://data.cityofchicago.org/Community-Economic-Development/TIF-Balance-Sheets/hezc-e4be
* tif_districts           : https://data.cityofchicago.org/Community-Economic-Development/Boundaries-Tax-Increment-Financing-Districts/iyec-2es5
* tif_projection_reports  : https://data.cityofchicago.org/Community-Economic-Development/TIF-Projection-Reports/zai4-r88e
* tif_status_eligibility  : https://data.cityofchicago.org/Community-Economic-Development/TIF-Status-and-Eligibility/3qsz-jemf

### County
* propclass : PDF 
* property_info : http://cookcountypropertyinfo.com/Pages/Pin-Results.aspx?pin= 
* taxcode : FOIA

### Safety
* crimes_2001_2011        : https://data.cityofchicago.org/Public-Safety/Crimes-2001-to-present/ijzp-q8t2
* crimes_2012             : https://data.cityofchicago.org/Public-Safety/Crimes-2001-to-present/ijzp-q8t2
* fbi_codes               : empty
* fire_stations           : https://data.cityofchicago.org/Public-Safety/Fire-Stations/28km-gtjn
* iucr_codes              : https://data.cityofchicago.org/Public-Safety/Chicago-Police-Department-Illinois-Uniform-Crime-R/c7ck-438e
* life_safety_evaluations : https://data.cityofchicago.org/Buildings/Life-Safety-Evaluations/qqqh-hgyw
* police_beats            : https://data.cityofchicago.org/Public-Safety/Boundaries-Police-Beats-deprecated-on-12-18-2012-/kd6k-pxkv
                        to be updated to https://data.cityofchicago.org/Public-Safety/Boundaries-Police-Beats-effective-12-19-2012-/dq28-4w9c
* police_stations         : https://data.cityofchicago.org/Public-Safety/Police-Stations/z8bn-74gv
* sex_offenders           : https://data.cityofchicago.org/Public-Safety/Sex-Offenders/vc9r-bqvy

### Historic / Landmarks
* historic_districts      : https://data.cityofchicago.org/Historic-Preservation/National-Register-of-Historic-Places/yw5d-szpx
* historic_resources      : https://data.cityofchicago.org/Historic-Preservation/National-Register-of-Historic-Places/yw5d-szpx
* landmarks               : https://data.cityofchicago.org/Historic-Preservation/Individual-Landmarks/tdab-kixi
* landmarks_no_bldg       : https://data.cityofchicago.org/Historic-Preservation/Individual-Landmarks/tdab-kixi

### Health
* asthma_hospitalizations   : https://data.cityofchicago.org/Health-Human-Services/Public-Health-Statistics-Asthma-hospitalizations-i/vazh-t57q
* chlamydia_females_15_44   : https://data.cityofchicago.org/Health-Human-Services/Public-Health-Statistics-Chlamydia-cases-among-fem/bz6k-73ti
* condom_distribution_sites : https://data.cityofchicago.org/Health-Human-Services/Condom-Distribution-Sites/azpf-uc4s
* deaths                    : https://data.cityofchicago.org/Health-Human-Services/Public-Health-Statistics-Selected-underlying-cause/j6cj-r444
* dentists                  : ??
* diabetes_hospitalizations : https://data.cityofchicago.org/Health-Human-Services/Public-Health-Statistics-Diabetes-hospitalizations/vekt-28b5
* food_inspection           : https://data.cityofchicago.org/Health-Human-Services/Food-Inspections/4ijn-s7e5
* gonorrhea_females_15_44   : https://data.cityofchicago.org/Health-Human-Services/Public-Health-Statistics-Gonorrhea-cases-for-femal/cgjw-mn43
* gonorrhea_males_15_44     : https://data.cityofchicago.org/Health-Human-Services/Public-health-statistics-Gonorrhea-cases-for-males/m5qn-gmjx
* hospitals                 : https://data.cityofchicago.org/Health-Human-Services/Hospitals-Chicago/ucpz-2r55 (shapefile)
* infant_mortality          : https://data.cityofchicago.org/Health-Human-Services/Public-Health-Statistics-Infant-mortality-in-Chica/bfhr-4ckq
* lead_screening_children   : https://data.cityofchicago.org/Health-Human-Services/Public-Health-Statistics-Screening-for-elevated-bl/v2z5-jyrq
* low_birth_weight          : https://data.cityofchicago.org/Health-Human-Services/Public-Health-Statistics-Low-birth-weight-in-Chica/fbxr-9u99
* mental_health_clinics     : https://data.cityofchicago.org/Health-Human-Services/Mental-Health-Clinics/v56e-cy8y (shapefile)
* neighborhood_health_clinics : https://data.cityofchicago.org/Health-Human-Services/Neighborhood-Health-Clinics/mw69-m6xi
* outpatient_registrations_by_zip_by_month_by_hospital : ??
* pre_term_births               : ??
* prenatal_care                 : https://data.cityofchicago.org/Health-Human-Services/Public-Health-Statistics-Prenatal-care-in-Chicago-/2q9j-hh6g
* sti_specialty_clinics         : https://data.cityofchicago.org/Health-Human-Services/STI-Specialty-Clinics-Map/aewr-nzrt (shapefile)
* tuberculosis                  : https://data.cityofchicago.org/Health-Human-Services/Public-Health-Statistics-Tuberculosis-cases-and-av/ndk3-zftj
* wic_offices                   : https://data.cityofchicago.org/Health-Human-Services/Women-Infant-Children-Health-Clinics/g85x-gwmp

### Environment
* farmers_markets_2012          : https://data.cityofchicago.org/Environment-Sustainable-Development/Farmers-Markets/hu6v-hsqb (shapefile)
* fishing_lake_bathymetry       : 
* forest_preserve_groves        : 
* forest_preserve_shelters      : 
* forest_preserve_trails        : 
* forestry                      : 
* natural_habitats              : 
* natural_habitats_comments     : 
* neighborspace_gardens         : 
* park_events                   : 
* parkbuildings_aug2012         :
* parkfacilities_aug2012        :  
* parks                         : 
* parks_public_art              :
* waterways                     : 
 
### Education
* boundarygrades1               :
* boundarygrades10              :
* boundarygrades11              :
* boundarygrades12              :
* boundarygrades2               :
* boundarygrades3               :
* boundarygrades4               :
* boundarygrades5               :
* boundarygrades6               :
* boundarygrades7               :
* boundarygrades8               :
* boundarygrades9               :
* boundarygradesk               :
* campus_parks                  :
* libraries                     :
* private_schools               :
* public_schools                :

### Transportation
* bike_racks            :  https://data.cityofchicago.org/Transportation/Bike-Racks/cbyb-69xx
* bike_routes           :  https://data.cityofchicago.org/Transportation/Bike-Routes/2wak-k8cp
* boulevards            :  https://data.cityofchicago.org/Environment-Sustainable-Development/Open-Spaces-Boulevards/sd36-arzm
* cook_co_hwy_juris     :  https://data.cityofchicago.org/Transportation/Cook-County-Highway-Department-Jurisdictions/2b73-3uqk
* major_streets         :  https://data.cityofchicago.org/Transportation/Major-Streets/ueqs-5wr6
* metra_lines           :  https://data.cityofchicago.org/Transportation/Metra-Lines/q8wx-dznq
* metra_stations        :  https://data.cityofchicago.org/Transportation/Metra-Stations/nqm8-q2ym
* pedway                :  " (probably a duplicate)
* pedway_routes         :  https://data.cityofchicago.org/Transportation/Pedway-Routes/savp-mfks
* riverwalk             :  https://data.cityofchicago.org/Environment-Sustainable-Development/Open-Spaces-Riverwalk/7nh7-nkau
* streets               :  https://data.cityofchicago.org/Transportation/Street-Center-Lines/xy4z-b6aa

### CTA
* bus_routes                                         :
* bus_stops                                          :
* cta_bus_garages                                    :
* cta_bus_owl                                        :
* cta_bus_ridership                                  :
* cta_bus_stops_routes                               :
* cta_digital_signs                                  :
* cta_el_ridership                                   :
* cta_fare_media_retail_outlets                      :
* cta_fare_media_retail_outlets_faretypes            :
* cta_rail_lines_iso                                 :
* cta_rail_stations_lines                            :
* owlroutes                                          :
* rail_lines                                         :
* rail_lines_prejct                                  :
* rail_stations                                      :

### Demographics
* births_and_birth_rates                             :
* census_blocks_families_husband_and_wife            :
* census_blocks_families_single_mother               :
* census_blocks_families_total                       :
* census_blocks_households                           :
* census_blocks_population_by_race                   :
* census_blocks_sex_by_age                           :
* census_tracts_ancestry                             :
* census_tracts_education                            :
* census_tracts_fertility                            :
* census_tracts_grandparents                         :
* census_tracts_household_income                     :
* census_tracts_households                           :
* census_tracts_housing                              :
* census_tracts_housing_bedrooms                     :
* census_tracts_housing_gross_rent                   :
* census_tracts_housing_heating                      :
* census_tracts_housing_mortgage_smoc                :
* census_tracts_housing_no_mortgage_smoc             :
* census_tracts_housing_occupants_per_room           :
* census_tracts_housing_rooms                        :
* census_tracts_housing_selected_characteristics     :
* census_tracts_housing_tenure                       :
* census_tracts_housing_units                        :
* census_tracts_housing_value                        :
* census_tracts_housing_year_moved_in                :
* census_tracts_languages_spoken_at_home             :
* census_tracts_marital_status                       :
* census_tracts_mobility                             :
* census_tracts_nativity                             :
* census_tracts_population                           :
* census_tracts_poverty                              :
* census_tracts_school_enrollment                    :
* census_tracts_transportation_to_work               :
* census_tracts_vehicles_available                   :
* census_tracts_veterans                             :
