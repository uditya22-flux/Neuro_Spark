-- The synthetic showcase has a deliberately broad, fixed 30-sector Layer 1
-- catalogue: six non-diagnostic visual-play groups of five.  Existing
-- fictional sessions may contain the earlier identifiers, so each new check
-- is NOT VALID: it governs all future writes without rejecting historical
-- showcase rows during this migration.

begin;

alter table public.synthetic_engine2_demo_tasks
  drop constraint if exists synthetic_engine2_demo_tasks_sector_check;
alter table public.synthetic_engine2_demo_attempts
  drop constraint if exists synthetic_engine2_demo_attempts_sector_check;
alter table public.synthetic_engine2_demo_events
  drop constraint if exists synthetic_engine2_demo_events_sector_check;

alter table public.synthetic_engine2_demo_tasks
  add constraint synthetic_engine2_demo_tasks_sector_check
  check (sector in (
    'mentalRotation', 'visualPatternCompletion', 'pointCloudAnomalyDetection',
    'mapRouteNavigation', 'visualSpatialConstruction',
    'chronologicalSequencing', 'narrativeEventOrdering', 'causeAndEffectChains',
    'rhythmicMotorSequencing', 'proceduralSequencing',
    'numberPatternRecognition', 'ruleDiscovery', 'multiAttributeSorting',
    'systemizing', 'quantitativeEstimation',
    'pictureAssociation', 'phonologicalPatternRecognition', 'wordlessInference',
    'analogyMapping', 'creativeStorytelling',
    'workingMemorySpan', 'visualSceneMemory', 'sustainedAttention',
    'auditorySequenceRecall', 'selectiveAttention',
    'emotionRecognition', 'perspectiveTaking', 'turnTakingStrategy',
    'musicalPatternRecognition', 'visualArtisticComposition'
  )) not valid;

alter table public.synthetic_engine2_demo_attempts
  add constraint synthetic_engine2_demo_attempts_sector_check
  check (sector in (
    'mentalRotation', 'visualPatternCompletion', 'pointCloudAnomalyDetection',
    'mapRouteNavigation', 'visualSpatialConstruction',
    'chronologicalSequencing', 'narrativeEventOrdering', 'causeAndEffectChains',
    'rhythmicMotorSequencing', 'proceduralSequencing',
    'numberPatternRecognition', 'ruleDiscovery', 'multiAttributeSorting',
    'systemizing', 'quantitativeEstimation',
    'pictureAssociation', 'phonologicalPatternRecognition', 'wordlessInference',
    'analogyMapping', 'creativeStorytelling',
    'workingMemorySpan', 'visualSceneMemory', 'sustainedAttention',
    'auditorySequenceRecall', 'selectiveAttention',
    'emotionRecognition', 'perspectiveTaking', 'turnTakingStrategy',
    'musicalPatternRecognition', 'visualArtisticComposition'
  )) not valid;

alter table public.synthetic_engine2_demo_events
  add constraint synthetic_engine2_demo_events_sector_check
  check (sector in (
    'mentalRotation', 'visualPatternCompletion', 'pointCloudAnomalyDetection',
    'mapRouteNavigation', 'visualSpatialConstruction',
    'chronologicalSequencing', 'narrativeEventOrdering', 'causeAndEffectChains',
    'rhythmicMotorSequencing', 'proceduralSequencing',
    'numberPatternRecognition', 'ruleDiscovery', 'multiAttributeSorting',
    'systemizing', 'quantitativeEstimation',
    'pictureAssociation', 'phonologicalPatternRecognition', 'wordlessInference',
    'analogyMapping', 'creativeStorytelling',
    'workingMemorySpan', 'visualSceneMemory', 'sustainedAttention',
    'auditorySequenceRecall', 'selectiveAttention',
    'emotionRecognition', 'perspectiveTaking', 'turnTakingStrategy',
    'musicalPatternRecognition', 'visualArtisticComposition'
  )) not valid;

commit;
