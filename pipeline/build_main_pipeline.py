import azureml.core
from azureml.core import Workspace
from azureml.pipeline.steps import CommandStep
from azureml.core.compute import AmlCompute, ComputeTarget
from azureml.core.compute_target import ComputeTargetException
from azureml.core.runconfig import RunConfiguration
from azureml.core import Environment
from azureml.pipeline.core import Pipeline, PublishedPipeline,StepSequence
from azureml.pipeline.core.schedule import ScheduleRecurrence, Schedule,TimeZone


#Define variables
experiment_name = "SRP_dbt_rebuild"
compute_name = 'ml-cc-srp001'
train_source_dir = "."
# train_entry_point = "sync_step.py"
environment_name = "dbt_deploy"
pipeline_name = "SRP DBT Rebuild"
pipeline_desc = "e"
pipeline_ver = 1.0
schedule_name = "Nightly"
schedule_desc = "Nightly Rebuild"


# Check core SDK version number
print("SDK version:", azureml.core.VERSION)

ws = Workspace.from_config()
print(ws.name, ws.resource_group, ws.location, ws.subscription_id, sep = '\n')\

#Define the environment and compute
env = Environment.get(workspace=ws, name=environment_name)
compute_target = ws.compute_targets[compute_name]

#Create the run configuration
run_config = RunConfiguration()
run_config.target = compute_target
run_config.environment = env

# Disable or delete existing pipeline
#Find the pipeline ID we want to schedule using the name
pipeline_id = None
for pipeline in PublishedPipeline.list(ws):
    if pipeline.name == pipeline_name:
        pipeline_id = pipeline.id
        break
if pipeline_id is not None:
    # find all schedules for this pipeline, and deactivate the schedules
    for sched in Schedule.list(ws):
        if sched.pipeline_id == pipeline_id:
            sched.disable()
            break

    pipeline.disable()


test_step = CommandStep(name="test dbt model deploy",
                         command="/usr/bin/bash dbt_build.sh test", 
                         compute_target=compute_target, 
                         runconfig=run_config,
                         source_directory='.',
                         allow_reuse=False)

prod_step = CommandStep(name="prod dbt model deploy",
                         command="/usr/bin/bash dbt_build.sh prod", 
                         compute_target=compute_target, 
                         runconfig=run_config,
                         source_directory='.',
                         allow_reuse=False)

# Build the pipeline
step_sequence = StepSequence(steps=[test_step,prod_step])
pipeline1 = Pipeline(workspace=ws, steps=step_sequence)
# pipeline1.submit('dbtScheduledBuild')

published_pipeline1 = pipeline1.publish(
     name=pipeline_name,
     description=pipeline_desc,
     version=pipeline_ver)


#Find the pipeline ID we want to schedule using the name
for pipeline in PublishedPipeline.list(ws):
    if pipeline.name == pipeline_name:
        pipeline_id = pipeline.id

#Create the schedule recurrence
recurrence = ScheduleRecurrence('Day',
                                interval=1,
                                start_time='2022-01-01T00:00:00',
                                hours=[2],
                                time_zone=TimeZone.EasternStandardTime)

#Create the schedule
recurring_schedule = Schedule.create(
    ws, name=schedule_name,
    description=schedule_desc,
    pipeline_id=pipeline_id,
    experiment_name=experiment_name,
    recurrence=recurrence)