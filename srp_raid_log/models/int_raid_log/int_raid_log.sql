
SELECT a.ID
	  , b.Title as application_id
	 -- , b.[EVSP_x0020__x0028_For_x0020_Anal]
	--  , b.field_6
      ,a.[RAIDCategory] as raid_category
      ,a.[Impact] as impact
      ,a.[Status] as status
      ,a.[ActionCategory] as action_category
      ,a.[IssueReportedBy] as issue_reported_by
      ,cast(cast(a.[StartDate]  as datetime) as date) as start_date
      ,cast(cast(a.[EndDate] as datetime) as date) as end_date
      ,cast(a.[Issue_x0020_Category] as varchar(1024)) as issue_category
      ,a.[IssueDescription] as issue_description
      ,cast(cast( a.[IssueIdentifiedDate] as datetime) as date) as issue_identification_date
      ,a.[Owner_x002f_Assignee] as owner_or_assignee
      ,cast(cast(a.[IssueResolvedDate] as datetime) as date) as issue_resolved_date
      ,a.[Observations] as observations
      ,a.[FinalResolution] as final_resolution
  FROM {{ref('base_evsp_raid_log')}} a
  join {{ref('base_pdo_raw_export')}}  b on a.ProjectNumberID = b.[ID]
