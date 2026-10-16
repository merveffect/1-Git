/*
    ============================================================================
    20. THE EXTERNAL ROLE LIBRARY — IS IT WORTH ADOPTING?
    ============================================================================
    Another team shared "B2C Research Audience - Job Title & Seniority
    Framework", grounded in the EURAXESS researcher career framework, UKRI
    guidance and the MORE4 R1-R4 career stages. 129 rows, and the Job title
    column holds semicolon-separated synonym clusters - 284 distinct titles
    once expanded, each with a sector, a subcategory and a proposed seniority
    category.

    Nothing is loaded for this. The 284 titles are inlined below, already
    normalised the same way int_title_distinct normalises ours - casefolded,
    punctuation stripped, whitespace collapsed, abbreviations expanded - so
    they join directly on dim_title_group.title.

    THE QUESTION THIS ANSWERS. 284 titles against our 310,299 is 0.09% by
    distinct value, which sounds negligible. But job title distributions are
    heavily skewed, so the share of RECORDS they cover is the number that
    decides whether this file is valuable. Query 1 is that number.

    If the coverage is large, the file becomes seeds/external_role_library.csv
    and the mapping from their taxonomy to our groups becomes a reviewable
    artefact. If it is small, it stays a reference document.
    ============================================================================
*/

-- the shared library, normalised to match our dictionary
create temp table external_titles as
select * from unnest([
  struct<title string, sector string, subcategory string, seniority string>
  ('academic clinical fellow', 'Academia', 'Postdoctoral & fellowship roles', 'Established / independent researcher'),
  ('academic research scientist', 'Academia', 'Research staff (non-faculty)', 'Variable / title alone insufficient'),
  ('adjunct faculty', 'Academia', 'Faculty', 'Variable / title alone insufficient'),
  ('adjunct professor', 'Academia', 'Faculty', 'Variable / title alone insufficient'),
  ('advanced research fellow', 'Academia', 'Postdoctoral & fellowship roles', 'Established / independent researcher'),
  ('affiliate professor', 'Academia', 'Faculty', 'Variable / title alone insufficient'),
  ('ahp', 'Healthcare', 'Healthcare professions', 'Variable / title alone insufficient'),
  ('ai research scientist', 'Industry', 'Scientist track', 'Variable / title alone insufficient'),
  ('allied health professional', 'Healthcare', 'Healthcare professions', 'Variable / title alone insufficient'),
  ('applications specialist', 'Cross-sector', 'Research support', 'Early-career & Support?'),
  ('applied data scientist', 'Industry', 'Specialised research roles', 'Variable / title alone insufficient'),
  ('applied scientist', 'Industry', 'Scientist track', 'Variable / title alone insufficient'),
  ('assistant professor', 'Academia', 'Faculty', 'Established / independent researcher'),
  ('assistant research professor', 'Academia', 'Research staff (non-faculty)', 'Senior research leader / expert'),
  ('associate dean', 'Academia', 'Academic & research leadership', 'Senior research leader / expert'),
  ('associate director', 'Industry', 'Management track', 'Senior research leader / expert'),
  ('associate professor', 'Academia', 'Faculty', 'Senior research leader / expert'),
  ('associate scientist', 'Industry', 'Scientist track', 'Early-career & Support'),
  ('attending', 'Healthcare', 'Clinical practice', 'Senior research leader / expert'),
  ('attending physician', 'Healthcare', 'Clinical practice', 'Senior research leader / expert'),
  ('attending surgeon', 'Healthcare', 'Clinical practice', 'Senior research leader / expert'),
  ('bachelor s student', 'Cross-sector', 'Students & trainees', 'Trainee'),
  ('between roles', 'Former or inactive', 'Employment status', 'Inactive'),
  ('bioinformatician', 'Industry', 'Specialised research roles', 'Variable / title alone insufficient'),
  ('biostatistician', 'Industry', 'Specialised research roles', 'Variable / title alone insufficient'),
  ('career break', 'Former or inactive', 'Employment status', 'Inactive'),
  ('centre director', 'Academia', 'Academic & research leadership', 'Senior research leader / expert'),
  ('chair', 'Academia', 'Faculty', 'Senior research leader / expert'),
  ('chair of department', 'Academia', 'Academic & research leadership', 'Senior research leader / expert'),
  ('chief science officer', 'Industry', 'Management track', 'Senior research leader / expert'),
  ('chief scientific officer cso', 'Industry', 'Management track', 'Senior research leader / expert'),
  ('clinical academic fellow', 'Cross-sector', 'Students & trainees', 'Trainee'),
  ('clinical academic nurse', 'Healthcare', 'Clinical research', 'Variable / title alone insufficient'),
  ('clinical director', 'Healthcare', 'Clinical practice', 'Senior research leader / expert'),
  ('clinical epidemiologist', 'Industry', 'Specialised research roles', 'Variable / title alone insufficient'),
  ('clinical fellow', 'Cross-sector', 'Students & trainees', 'Trainee'),
  ('clinical investigator', 'Healthcare', 'Clinical research', 'Variable / title alone insufficient'),
  ('clinical pharmacist', 'Healthcare', 'Clinical research', 'Variable / title alone insufficient'),
  ('clinical pharmacologist', 'Healthcare', 'Clinical research', 'Variable / title alone insufficient'),
  ('clinical pharmacology scientist', 'Healthcare', 'Clinical research', 'Variable / title alone insufficient'),
  ('clinical practitioner', 'Healthcare', 'Clinical practice', 'Variable / title alone insufficient'),
  ('clinical research assistant', 'Cross-sector', 'Research support', 'Early-career & Support'),
  ('clinical research fellow', 'Academia', 'Postdoctoral & fellowship roles', 'Established / independent researcher'),
  ('clinical researcher', 'Healthcare', 'Clinical research', 'Variable / title alone insufficient'),
  ('clinical scientist', 'Healthcare', 'Clinical research', 'Variable / title alone insufficient'),
  ('clinical study coordinator', 'Cross-sector', 'Research support', 'Early-career & Support'),
  ('clinical trials assistant', 'Cross-sector', 'Research support', 'Early-career & Support'),
  ('clinician', 'Healthcare', 'Clinical practice', 'Variable / title alone insufficient'),
  ('clinician scientist fellow', 'Academia', 'Postdoctoral & fellowship roles', 'Established / independent researcher'),
  ('co-lead investigator', 'Academia', 'Academic & research leadership', 'Senior research leader / expert'),
  ('co-principal investigator', 'Academia', 'Academic & research leadership', 'Senior research leader / expert'),
  ('computational biologist', 'Industry', 'Specialised research roles', 'Variable / title alone insufficient'),
  ('computational scientist', 'Industry', 'Specialised research roles', 'Variable / title alone insufficient'),
  ('consultant', 'Healthcare', 'Clinical practice', 'Senior research leader / expert'),
  ('consultant clinician', 'Healthcare', 'Healthcare professions', 'Senior research leader / expert'),
  ('consultant physician', 'Healthcare', 'Clinical practice', 'Senior research leader / expert'),
  ('consultant practitioner', 'Healthcare', 'Healthcare professions', 'Senior research leader / expert'),
  ('consultant surgeon', 'Healthcare', 'Clinical practice', 'Senior research leader / expert'),
  ('core scientist', 'Academia', 'Research staff (non-faculty)', 'Established / independent researcher'),
  ('corporate fellow', 'Industry', 'Scientist track', 'Variable / title alone insufficient'),
  ('data scientist', 'Industry', 'Specialised research roles', 'Variable / title alone insufficient'),
  ('dean', 'Academia', 'Academic & research leadership', 'Senior research leader / expert'),
  ('department head', 'Academia', 'Academic & research leadership', 'Senior research leader / expert'),
  ('deputy dean', 'Academia', 'Academic & research leadership', 'Senior research leader / expert'),
  ('deputy director', 'Industry', 'Management track', 'Senior research leader / expert'),
  ('development scientist', 'Industry', 'Specialised research roles', 'Variable / title alone insufficient'),
  ('director', 'Industry', 'Management track', 'Senior research leader / expert'),
  ('director of research', 'Industry', 'Management track', 'Senior research leader / expert'),
  ('director-general', 'Academia', 'Academic & research leadership', 'Senior research leader / expert'),
  ('distinguished fellow', 'Industry', 'Scientist track', 'Senior research leader / expert'),
  ('distinguished professor', 'Academia', 'Faculty', 'Senior research leader / expert'),
  ('distinguished research scientist', 'Industry', 'Scientist track', 'Senior research leader / expert'),
  ('distinguished scientist', 'Industry', 'Scientist track', 'Senior research leader / expert'),
  ('doctor', 'Healthcare', 'Clinical practice', 'Variable / title alone insufficient'),
  ('doctoral candidate', 'Cross-sector', 'Students & trainees', 'Trainee'),
  ('doctoral researcher', 'Cross-sector', 'Students & trainees', 'Trainee'),
  ('economist', 'Government & public sector', 'Policy & analysis', 'Variable / title alone insufficient'),
  ('education fellow', 'Academia', 'Postdoctoral & fellowship roles', 'Established / independent researcher'),
  ('emeritus professor', 'Former or inactive', 'Employment status', 'Inactive'),
  ('emeritus researcher', 'Former or inactive', 'Employment status', 'Inactive'),
  ('emeritus scientist', 'Former or inactive', 'Employment status', 'Inactive'),
  ('endowed chair professor', 'Academia', 'Faculty', 'Senior research leader / expert'),
  ('endowed professor', 'Academia', 'Faculty', 'Senior research leader / expert'),
  ('epidemiologist', 'Industry', 'Specialised research roles', 'Variable / title alone insufficient'),
  ('executive dean', 'Academia', 'Academic & research leadership', 'Senior research leader / expert'),
  ('executive director', 'Industry', 'Management track', 'Senior research leader / expert'),
  ('executive research director', 'Industry', 'Management track', 'Senior research leader / expert'),
  ('facility manager', 'Cross-sector', 'Research support', 'Variable / title alone insufficient'),
  ('faculty dean', 'Academia', 'Academic & research leadership', 'Senior research leader / expert'),
  ('faculty head', 'Academia', 'Academic & research leadership', 'Senior research leader / expert'),
  ('fellow', 'Academia', 'Postdoctoral & fellowship roles', 'Established / independent researcher'),
  ('formulation scientist', 'Industry', 'Specialised research roles', 'Variable / title alone insufficient'),
  ('full professor', 'Academia', 'Faculty', 'Senior research leader / expert'),
  ('functional director', 'Industry', 'Management track', 'Senior research leader / expert'),
  ('government scientist', 'Government & public sector', 'Research & science roles', 'Variable / title alone insufficient'),
  ('graduate research assistant', 'Cross-sector', 'Research support', 'Early-career & Support'),
  ('grants manager', 'Cross-sector', 'Research support', 'Variable / title alone insufficient'),
  ('group leader', 'Academia', 'Academic & research leadership', 'Senior research leader / expert'),
  ('head of faculty', 'Academia', 'Academic & research leadership', 'Senior research leader / expert'),
  ('head of r&d', 'Industry', 'Management track', 'Senior research leader / expert'),
  ('head of school', 'Academia', 'Academic & research leadership', 'Senior research leader / expert'),
  ('head of scientific affairs', 'Industry', 'Management track', 'Senior research leader / expert'),
  ('health professional', 'Healthcare', 'Healthcare professions', 'Variable / title alone insufficient'),
  ('healthcare professional', 'Healthcare', 'Healthcare professions', 'Variable / title alone insufficient'),
  ('healthcare scientist', 'Healthcare', 'Clinical research', 'Variable / title alone insufficient'),
  ('honorary researcher', 'Former or inactive', 'Employment status', 'Inactive'),
  ('institute director', 'Academia', 'Academic & research leadership', 'Senior research leader / expert'),
  ('investigator', 'NGOs, think tanks & independent research institutes', 'Research roles', 'Early-career & Support'),
  ('junior professor', 'Academia', 'Faculty', 'Established / independent researcher'),
  ('lab director', 'Academia', 'Academic & research leadership', 'Senior research leader / expert'),
  ('lab head', 'Academia', 'Academic & research leadership', 'Senior research leader / expert'),
  ('lab manager', 'Cross-sector', 'Research support', 'Variable / title alone insufficient'),
  ('lab technician', 'Cross-sector', 'Research support', 'Early-career & Support'),
  ('laboratory head', 'Academia', 'Academic & research leadership', 'Senior research leader / expert'),
  ('laboratory manager', 'Cross-sector', 'Research support', 'Variable / title alone insufficient'),
  ('laboratory technician', 'Cross-sector', 'Research support', 'Early-career & Support'),
  ('lead investigator', 'Academia', 'Academic & research leadership', 'Senior research leader / expert'),
  ('lead scientist', 'Industry', 'Scientist track', 'Established / independent researcher'),
  ('lead staff scientist', 'Academia', 'Research staff (non-faculty)', 'Established / independent researcher'),
  ('lecturer', 'Academia', 'Faculty', 'Established / independent researcher'),
  ('lecturer in teaching track', 'Academia', 'Postdoctoral & fellowship roles', 'Established / independent researcher'),
  ('ma student', 'Cross-sector', 'Students & trainees', 'Trainee'),
  ('machine learning research scientist', 'Industry', 'Scientist track', 'Variable / title alone insufficient'),
  ('machine learning scientist', 'Industry', 'Scientist track', 'Variable / title alone insufficient'),
  ('master of philosophy student', 'Cross-sector', 'Students & trainees', 'Trainee'),
  ('masters student', 'Cross-sector', 'Students & trainees', 'Trainee'),
  ('maître de conférences', 'Academia', 'Faculty', 'Established / independent researcher'),
  ('md student', 'Cross-sector', 'Students & trainees', 'Trainee'),
  ('medical director', 'Healthcare', 'Clinical practice', 'Senior research leader / expert'),
  ('medical doctor', 'Healthcare', 'Clinical practice', 'Variable / title alone insufficient'),
  ('medical fellow', 'Cross-sector', 'Students & trainees', 'Trainee'),
  ('medical resident', 'Cross-sector', 'Students & trainees', 'Trainee'),
  ('medical statistician', 'Industry', 'Specialised research roles', 'Variable / title alone insufficient'),
  ('medical student', 'Cross-sector', 'Students & trainees', 'Trainee'),
  ('ml researcher', 'Industry', 'Scientist track', 'Variable / title alone insufficient'),
  ('modelling scientist', 'Industry', 'Specialised research roles', 'Variable / title alone insufficient'),
  ('mphil student', 'Cross-sector', 'Students & trainees', 'Trainee'),
  ('mres student', 'Cross-sector', 'Students & trainees', 'Trainee'),
  ('msc student', 'Cross-sector', 'Students & trainees', 'Trainee'),
  ('named chair', 'Academia', 'Faculty', 'Senior research leader / expert'),
  ('named distinguished professor', 'Academia', 'Faculty', 'Senior research leader / expert'),
  ('not currently working', 'Former or inactive', 'Employment status', 'Inactive'),
  ('nurse researcher', 'Healthcare', 'Clinical research', 'Variable / title alone insufficient'),
  ('official statistician', 'Government & public sector', 'Policy & analysis', 'Variable / title alone insufficient'),
  ('often tenured associate professor', 'Academia', 'Faculty', 'Senior research leader / expert'),
  ('pd', 'Academia', 'Faculty', 'Established / independent researcher'),
  ('permanent scientist', 'Academia', 'Research staff (non-faculty)', 'Established / independent researcher'),
  ('pharmacist', 'Healthcare', 'Clinical research', 'Variable / title alone insufficient'),
  ('pharmacoepidemiologist', 'Industry', 'Specialised research roles', 'Variable / title alone insufficient'),
  ('phd candidate', 'Cross-sector', 'Students & trainees', 'Trainee'),
  ('phd student', 'Cross-sector', 'Students & trainees', 'Trainee'),
  ('physician', 'Healthcare', 'Clinical practice', 'Variable / title alone insufficient'),
  ('policy analyst', 'Government & public sector', 'Policy & analysis', 'Established / independent researcher'),
  ('policy fellow', 'NGOs, think tanks & independent research institutes', 'Research roles', 'Established / independent researcher'),
  ('policy researcher', 'Government & public sector', 'Policy & analysis', 'Established / independent researcher'),
  ('postdoc', 'Academia', 'Postdoctoral & fellowship roles', 'Early-career & Support'),
  ('postdoc fellow', 'Academia', 'Postdoctoral & fellowship roles', 'Early-career & Support'),
  ('postdoctoral associate', 'Academia', 'Postdoctoral & fellowship roles', 'Early-career & Support'),
  ('postdoctoral fellow', 'Academia', 'Postdoctoral & fellowship roles', 'Early-career & Support'),
  ('postdoctoral researcher', 'Academia', 'Postdoctoral & fellowship roles', 'Early-career & Support'),
  ('postgraduate researcher', 'Cross-sector', 'Students & trainees', 'Trainee'),
  ('principal investigator', 'Academia', 'Academic & research leadership', 'Senior research leader / expert'),
  ('principal research fellow', 'Academia', 'Postdoctoral & fellowship roles', 'Senior research leader / expert'),
  ('principal research scientist', 'Academia', 'Research staff (non-faculty)', 'Senior research leader / expert'),
  ('principal researcher', 'NGOs, think tanks & independent research institutes', 'Research roles', 'Senior research leader / expert'),
  ('principal science officer', 'Government & public sector', 'Research & science roles', 'Senior research leader / expert'),
  ('principal scientific officer', 'Government & public sector', 'Research & science roles', 'Senior research leader / expert'),
  ('principal scientist', 'Academia', 'Research staff (non-faculty)', 'Senior research leader / expert'),
  ('privatdozent', 'Academia', 'Faculty', 'Established / independent researcher'),
  ('private lecturer', 'Academia', 'Faculty', 'Established / independent researcher'),
  ('product development scientist', 'Industry', 'Specialised research roles', 'Variable / title alone insufficient'),
  ('professor', 'Academia', 'Faculty', 'Senior research leader / expert'),
  ('professor emerita', 'Former or inactive', 'Employment status', 'Inactive'),
  ('professor emeritus', 'Former or inactive', 'Employment status', 'Inactive'),
  ('professor of research', 'Academia', 'Research staff (non-faculty)', 'Senior research leader / expert'),
  ('professorial research fellow in some institutions', 'Academia', 'Postdoctoral & fellowship roles', 'Senior research leader / expert'),
  ('program leader', 'Academia', 'Academic & research leadership', 'Variable / title alone insufficient'),
  ('programme director', 'Academia', 'Academic & research leadership', 'Variable / title alone insufficient'),
  ('programme head', 'NGOs, think tanks & independent research institutes', 'Research roles', 'Senior research leader / expert'),
  ('programme leader', 'Academia', 'Academic & research leadership', 'Variable / title alone insufficient'),
  ('project assistant', 'Cross-sector', 'Research support', 'Early-career & Support'),
  ('project coordinator', 'Cross-sector', 'Research support', 'Early-career & Support'),
  ('project researcher', 'Academia', 'Research staff (non-faculty)', 'Early-career & Support'),
  ('project scientist', 'Industry', 'Scientist track', 'Established / independent researcher'),
  ('public-sector scientist', 'Government & public sector', 'Research & science roles', 'Variable / title alone insufficient'),
  ('r&d head', 'Industry', 'Management track', 'Senior research leader / expert'),
  ('r&d manager', 'Industry', 'Management track', 'Established / independent researcher'),
  ('r&d scientist', 'Industry', 'Scientist track', 'Variable / title alone insufficient'),
  ('reader', 'Academia', 'Faculty', 'Senior research leader / expert'),
  ('regulatory affairs scientist', 'Industry', 'Specialised research roles', 'Variable / title alone insufficient'),
  ('regulatory scientist', 'Industry', 'Specialised research roles', 'Variable / title alone insufficient'),
  ('research analyst', 'Government & public sector', 'Research & science roles', 'Early-career & Support'),
  ('research and development manager', 'Industry', 'Management track', 'Established / independent researcher'),
  ('research assistant', 'Cross-sector', 'Research support', 'Early-career & Support'),
  ('research assistant professor', 'Academia', 'Research staff (non-faculty)', 'Senior research leader / expert'),
  ('research associate', 'Academia', 'Research staff (non-faculty)', 'Early-career & Support'),
  ('research coordinator', 'Cross-sector', 'Research support', 'Early-career & Support'),
  ('research director', 'Industry', 'Management track', 'Senior research leader / expert'),
  ('research economist', 'Government & public sector', 'Policy & analysis', 'Variable / title alone insufficient'),
  ('research executive', 'Government & public sector', 'Research & science roles', 'Early-career & Support'),
  ('research fellow', 'Academia', 'Postdoctoral & fellowship roles', 'Established / independent researcher'),
  ('research fellow in some systems', 'Academia', 'Postdoctoral & fellowship roles', 'Early-career & Support'),
  ('research group leader', 'Academia', 'Academic & research leadership', 'Senior research leader / expert'),
  ('research intern', 'Cross-sector', 'Students & trainees', 'Trainee'),
  ('research manager', 'Cross-sector', 'Research support', 'Variable / title alone insufficient'),
  ('research officer', 'Government & public sector', 'Research & science roles', 'Early-career & Support'),
  ('research pharmacist', 'Healthcare', 'Clinical research', 'Variable / title alone insufficient'),
  ('research placement student', 'Cross-sector', 'Students & trainees', 'Trainee'),
  ('research professor', 'Academia', 'Research staff (non-faculty)', 'Senior research leader / expert'),
  ('research programme coordinator', 'Cross-sector', 'Research support', 'Early-career & Support'),
  ('research programme manager', 'Cross-sector', 'Research support', 'Variable / title alone insufficient'),
  ('research scientist', 'Academia', 'Research staff (non-faculty)', 'Variable / title alone insufficient'),
  ('research statistician', 'Government & public sector', 'Policy & analysis', 'Variable / title alone insufficient'),
  ('research technician', 'Cross-sector', 'Research support', 'Early-career & Support'),
  ('researcher', 'NGOs, think tanks & independent research institutes', 'Research roles', 'Early-career & Support'),
  ('resident doctor', 'Cross-sector', 'Students & trainees', 'Trainee'),
  ('resident physician', 'Cross-sector', 'Students & trainees', 'Trainee'),
  ('retired academic', 'Former or inactive', 'Employment status', 'Inactive'),
  ('retired professor', 'Former or inactive', 'Employment status', 'Inactive'),
  ('retired researcher', 'Former or inactive', 'Employment status', 'Inactive'),
  ('retired scientist', 'Former or inactive', 'Employment status', 'Inactive'),
  ('safety scientist', 'Industry', 'Specialised research roles', 'Variable / title alone insufficient'),
  ('science officer', 'Government & public sector', 'Research & science roles', 'Established / independent researcher'),
  ('scientific affairs director', 'Industry', 'Management track', 'Senior research leader / expert'),
  ('scientific fellow', 'Industry', 'Scientist track', 'Variable / title alone insufficient'),
  ('scientific lead', 'Industry', 'Scientist track', 'Established / independent researcher'),
  ('scientific officer', 'Government & public sector', 'Research & science roles', 'Established / independent researcher'),
  ('scientific technician', 'Cross-sector', 'Research support', 'Early-career & Support'),
  ('scientist', 'Industry', 'Scientist track', 'Early-career & Support'),
  ('scientist i', 'Industry', 'Scientist track', 'Early-career & Support'),
  ('scientist ii', 'Industry', 'Scientist track', 'Early-career & Support'),
  ('scientist iii', 'Industry', 'Scientist track', 'Established / independent researcher'),
  ('senior director', 'Industry', 'Management track', 'Senior research leader / expert'),
  ('senior fellow', 'Academia', 'Postdoctoral & fellowship roles', 'Established / independent researcher'),
  ('senior lecturer', 'Academia', 'Faculty', 'Senior research leader / expert'),
  ('senior manager', 'Industry', 'Management track', 'Senior research leader / expert'),
  ('senior postdoctoral associate', 'Academia', 'Research staff (non-faculty)', 'Established / independent researcher'),
  ('senior principal research scientist', 'Industry', 'Scientist track', 'Senior research leader / expert'),
  ('senior principal scientist', 'Industry', 'Scientist track', 'Senior research leader / expert'),
  ('senior r&d manager', 'Industry', 'Management track', 'Senior research leader / expert'),
  ('senior research analyst', 'NGOs, think tanks & independent research institutes', 'Research roles', 'Established / independent researcher'),
  ('senior research associate', 'Academia', 'Research staff (non-faculty)', 'Established / independent researcher'),
  ('senior research director', 'Industry', 'Management track', 'Senior research leader / expert'),
  ('senior research fellow', 'Academia', 'Postdoctoral & fellowship roles', 'Established / independent researcher'),
  ('senior research manager', 'Industry', 'Management track', 'Senior research leader / expert'),
  ('senior research scientist', 'Academia', 'Research staff (non-faculty)', 'Established / independent researcher'),
  ('senior research technician', 'Cross-sector', 'Research support', 'Early-career & Support?'),
  ('senior researcher', 'NGOs, think tanks & independent research institutes', 'Research roles', 'Established / independent researcher'),
  ('senior science officer', 'Government & public sector', 'Research & science roles', 'Established / independent researcher'),
  ('senior scientific officer', 'Government & public sector', 'Research & science roles', 'Established / independent researcher'),
  ('senior scientist', 'Academia', 'Research staff (non-faculty)', 'Established / independent researcher'),
  ('senior staff scientist', 'Academia', 'Research staff (non-faculty)', 'Established / independent researcher'),
  ('senior technician', 'Cross-sector', 'Research support', 'Early-career & Support?'),
  ('specialist physician', 'Healthcare', 'Clinical practice', 'Senior research leader / expert'),
  ('staff physician', 'Healthcare', 'Clinical practice', 'Senior research leader / expert'),
  ('staff research scientist', 'Industry', 'Scientist track', 'Established / independent researcher'),
  ('staff scientist', 'Academia', 'Research staff (non-faculty)', 'Established / independent researcher'),
  ('statistician', 'Government & public sector', 'Policy & analysis', 'Variable / title alone insufficient'),
  ('study coordinator', 'Cross-sector', 'Research support', 'Early-career & Support'),
  ('summer intern', 'Cross-sector', 'Students & trainees', 'Trainee'),
  ('surgeon', 'Healthcare', 'Clinical practice', 'Senior research leader / expert'),
  ('teaching fellow', 'Academia', 'Postdoctoral & fellowship roles', 'Established / independent researcher'),
  ('team lead', 'Industry', 'Management track', 'Established / independent researcher'),
  ('team leader', 'Academia', 'Academic & research leadership', 'Senior research leader / expert'),
  ('technical specialist', 'Cross-sector', 'Research support', 'Early-career & Support?'),
  ('technology specialist', 'Cross-sector', 'Research support', 'Early-career & Support?'),
  ('tenure-track assistant professor', 'Academia', 'Faculty', 'Established / independent researcher'),
  ('toxicologist', 'Industry', 'Specialised research roles', 'Variable / title alone insufficient'),
  ('translational researcher', 'Industry', 'Specialised research roles', 'Variable / title alone insufficient'),
  ('translational scientist', 'Industry', 'Specialised research roles', 'Variable / title alone insufficient'),
  ('trial coordinator', 'Cross-sector', 'Research support', 'Early-career & Support'),
  ('undergraduate student', 'Cross-sector', 'Students & trainees', 'Trainee'),
  ('unemployed', 'Former or inactive', 'Employment status', 'Inactive'),
  ('university lecturer', 'Academia', 'Faculty', 'Established / independent researcher'),
  ('university professor', 'Academia', 'Faculty', 'Senior research leader / expert'),
  ('university research fellow', 'Academia', 'Postdoctoral & fellowship roles', 'Established / independent researcher'),
  ('vice dean', 'Academia', 'Academic & research leadership', 'Senior research leader / expert'),
  ('vice president r&d', 'Industry', 'Management track', 'Senior research leader / expert'),
  ('vice president research', 'Industry', 'Management track', 'Senior research leader / expert'),
  ('visiting faculty', 'Academia', 'Faculty', 'Variable / title alone insufficient'),
  ('visiting professor', 'Academia', 'Faculty', 'Variable / title alone insufficient'),
  ('visiting scholar', 'Academia', 'Faculty', 'Variable / title alone insufficient'),
  ('vp of research and development', 'Industry', 'Management track', 'Senior research leader / expert'),
  ('vp research', 'Industry', 'Management track', 'Senior research leader / expert')
]);


-- ###########################################################################
-- 1. COVERAGE — the number that decides everything else
--
--    Not "how many of their titles do we know" but "how much of our data do
--    their titles account for".
-- ###########################################################################
SELECT
    COUNT(*)                                                    AS their_titles,
    COUNTIF(d.title IS NOT NULL)                                AS found_in_our_dictionary,
    ROUND(COUNTIF(d.title IS NOT NULL) / COUNT(*), 4)           AS share_of_their_titles,
    SUM(COALESCE(d.frequency, 0))                               AS our_records_covered,
    ROUND(SUM(COALESCE(d.frequency, 0))
          / (SELECT SUM(frequency) FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group`), 4) AS share_of_all_records
FROM external_titles e
LEFT JOIN `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group` d USING (title);


-- ###########################################################################
-- 2. DO WE AGREE? Their seniority category against our title group.
--
--    These answer different questions - they ask how senior a researcher is,
--    we ask what the person does - so this is not a correctness check. It is
--    a map. Read it to see which of their categories correspond to which of
--    our groups, and where one of theirs splits across several of ours.
-- ###########################################################################
SELECT
    e.seniority                                 AS their_seniority,
    COALESCE(d.title_group, '(not in our dictionary)') AS our_title_group,
    COUNT(*)                                    AS titles,
    SUM(COALESCE(d.frequency, 0))               AS records,
    ROUND(AVG(d.similarity), 3)                 AS avg_similarity
FROM external_titles e
LEFT JOIN `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group` d USING (title)
GROUP BY their_seniority, our_title_group
ORDER BY records DESC;


-- ###########################################################################
-- 3. ANCHOR CANDIDATES — their titles we do not hold at all
--
--    A title here is one of two things: a term that genuinely never appears
--    in ORCID, or a gap in our dictionary. The sector and subcategory say
--    which group it would belong to, so this is the harvest list.
--
--    Read the Healthcare and Clinical rows first. practitioner is our
--    weakest group at 40.5% low-confidence and it carries the whole
--    healthcare audience.
-- ###########################################################################
SELECT
    e.sector,
    e.subcategory,
    e.title,
    e.seniority
FROM external_titles e
LEFT JOIN `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group` d USING (title)
WHERE d.title IS NULL
ORDER BY
    CASE WHEN e.sector = 'Healthcare' OR e.subcategory LIKE '%Clinical%' THEN 0 ELSE 1 END,
    e.sector, e.subcategory, e.title;


-- ###########################################################################
-- 4. THE HIGH-TRAFFIC OVERLAP — where adopting their view would matter most
--
--    Their titles that we DO hold, ordered by how many of our records carry
--    them. A disagreement high in this list is worth a human decision; one at
--    the bottom is not.
-- ###########################################################################
SELECT
    e.title,
    d.frequency,
    d.title_group                   AS our_group,
    ROUND(d.similarity, 3)          AS similarity,
    d.decision_source,
    e.sector                        AS their_sector,
    e.seniority                     AS their_seniority
FROM external_titles e
JOIN `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group` d USING (title)
WHERE d.frequency >= 1000
ORDER BY d.frequency DESC
LIMIT 80;


-- ###########################################################################
-- 5. ANY OTHER RETIRED OR HONORARY TITLES WE STILL HOLD?
--
--     Marketing confirmed on 2026-10-16 that a retired professor is not a
--     researcher, and 14 titles from the external library are now rejected:
--     emeritus professor, professor emeritus, professor emerita, retired
--     professor, retired academic, emeritus researcher, emeritus scientist,
--     honorary researcher, retired researcher, retired scientist, not
--     currently working, career break, unemployed, between roles.
--
--     But that list is 14 titles and our dictionary holds 310,299. The same
--     status is written many other ways, and most of them are not English.
--     Prefix stems only - no trailing word boundary, which is what made the
--     organisation patterns fail silently for months.
--
--     Judge each row. 'honorary professor' is not necessarily retired, and
--     'former' appears in contexts that have nothing to do with status.
-- ###########################################################################
SELECT
    title,
    frequency,
    title_group,
    ROUND(similarity, 3)    AS similarity,
    decision_source
FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_dictionary.dim_title_group`
WHERE is_assigned
  AND REGEXP_CONTAINS(title, r'\b(emerit|émérit|retired|retir|honorar|honorair|former|ex-|emekli|jubilad|pension|ruhestand|aposentad|gepensioneerd|emerytowan)')
ORDER BY frequency DESC
LIMIT 60;


-- ###########################################################################
-- 6. HOW MUCH WOULD "CURRENT POSTS ONLY" COST?
--
--     THE LIMIT OF THE OVERRIDES ABOVE. Rejecting 'professor emeritus' stops
--     that RECORD counting. It does not necessarily remove the PERSON: if
--     they also hold an earlier Professor post that has ended, that record
--     still qualifies them, because seven of the eight roles run with
--     current_only: false.
--
--     So the overrides remove retired EVIDENCE, not retired PEOPLE. Removing
--     the people needs current_only: true on the role, and that is a much
--     bigger change - it also drops everyone whose current post simply is
--     not recorded in ORCID, and many profiles have none.
--
--     This sizes it before anyone decides. fct_researcher_roles already
--     prefers a current record when picking each person's representative,
--     so a row with is_current = false means the person has NO current post
--     supporting that role.
-- ###########################################################################
SELECT
    role_key,
    COUNT(DISTINCT snid)                                        AS people_now,
    COUNT(DISTINCT IF(is_current, snid, NULL))                  AS people_if_current_only,
    COUNT(DISTINCT IF(NOT is_current, snid, NULL))              AS would_be_lost,
    ROUND(COUNT(DISTINCT IF(NOT is_current, snid, NULL))
          / COUNT(DISTINCT snid), 4)                            AS share_lost
FROM `dat-analytics-eng-ec869189.dev_orcid_role_identifier_scoring.fct_researcher_roles`
WHERE role_label = 'CONFIRMED'
GROUP BY role_key
ORDER BY would_be_lost DESC;
