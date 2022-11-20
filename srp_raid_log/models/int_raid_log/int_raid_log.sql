
SELECT a.ID
	  , b.Title as application_id
	 -- , b.[EVSP_x0020__x0028_For_x0020_Anal]
	--  , b.field_6
      ,a.[RAIDCategory] as raid_category
      ,a.[Impact] as impact
      ,a.[Status] as status
      ,a.[ActionCategory] as action_category
      ,a.[IssueReportedBy] as issue_reported_by
      ,a.[StartDate] as start_dateS
      ,a.[EndDate] as end_date
      ,a.[IssueDescription] as issue_description
      ,a.[IssueIdentifiedDate] as issue_identification_date
      ,a.[Owner_x002f_Assignee] as owner_or_assignee
      ,a.[IssueResolvedDate] as issue_resolved_date
      ,a.[Observations] as observations
      ,a.[FinalResolution] as final_resolution
  FROM {{ref('base_evsp_raid_log')}} a
  join {{ref('base_pdo_raw_export')}}  b on a.ProjectNumberID = b.[ID]
