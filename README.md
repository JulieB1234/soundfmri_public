# soundfmri_public
##### See codes' comments for details about input and output
##### Data will be available upon reasonable request to juliechezboyer@wanadoo.fr
##### See preprint https://doi.org/10.64898/2026.06.17.732590

## 1. Experimental scripts (main directory) - MATLAB

- expe_active.m
- expe_passive.m
- expe_staircase.m (before all sessions)
- expe_pdc.m (control passive dot counting)


## 2. Analyses scripts for univariate fMRI (directory analysis_univariateGLM) - MATLAB
1st level codes ==> then manual 2nd level in SPM GUI

### GLM1 (parametric modulation)
- AP_conjunction_GLM1.m and associated functions - for main parametric modulation analyses, Active & Passive conditions
  - timing_files_active.m
  - timing_files_passive.m
  - FirstLevelParameters_SF3.m
 
- passive dot counting control condition (FFX - no 2nd level) = PassiveDotCounting_FFX.m and associated functions
  - FirstLevelParameters_FFX.m
  - timing_files_passiveDC_justpmod.m

- passive alone for covariate effect control analysis = ControlPassivePMOD_alone.m and associated functions
  - timing_files_passive.m
  - FirstLevelParameters_SF2.m


### GLM2 (FIR) - only 1st level then custom script

FIRactiveGLM2.m and associated functions
- timing_files_FIRactive.m
- FirstLevelParameters_FIRactive.m

FIRpassiveGLM2.m and associated functions
- timing_files_FIRpassive.m
- FirstLevelParameters_FIRpassive.m

THEN custom script for group:
- FIR_2ndLevel_partI.m
- FIR_2ndLevel_partII.m


### GLM3 (heard / not heard)
#### GLM3a
- Active_audib_unconscious_GLM3a.m and associated functions - for heard minus not heard AND not heard minus no sound in Active condition
  - timing_files_audibPerSNR_unc2_nosave.m
  - FirstLevelParameters_audibPerSNR_unconscious2.m
  - Contrasts_audibPerSNR_unconscious.m

#### GLM3b
- passive_unconscious_GLM3b.m and associated functions - for "other (not heard)" minus "no sound" in Passive condition
  - timing_files_mw3_ai_unc2.m
  - FirstLevelParameters_mw3_unc2.m

#### GLM3c
- Passive_mindwandering_GLM3c.m and associated functions - for "sound (heard)" minus "other (not heard)" in Passive condition
  - timing_files_mw.m
  - FirstLevelParameters_mw.m

#### GLM3d
- passive_mindwandering2_GLM3d.m and associated functions - alternative to GLM3c
  - timing_files_mw3_ai.m
  - FirstLevelParameters_mw3.m

### additional multiple comparison correction - treeBH - MATLAB
treeBH_univariate.m

## 3. Behavioural results figures (directory behav) - MATLAB
- indiv.m (indiv figures)
- group.m (group figures)

## 4. Pupil analyses (directory pupil) - MATLAB
- pupil_preprocessing.m (pre-processing)
- pupil_plot.m (plot group figures)

## 5. Single-trial analyses (directory analysis_singletrial) - MATLAB / PYTHON
### 5.1. single-trial GLM (using GLMsingle toolbox)
- Run GLMsingle 
  - complete_forGLMSingle_active_V3.m
  - complete_forGLMSingle_passive_V3.m

### 5.2. ROI definition and single-trial extraction
- Then get GLM1-based individual clusters
  - indiv_clusters.m (get individual responding clusters from GLM1 results)
  - cluster_ROIs.m (overlap with atlas-based Heschl => primary auditory 'A1' / extra primary audirtory 'noA1')

- Then extract single-trial betas from clusters
  - ExtractionSingle_indivClusters_V2.m

### 5.3. decoding (using TheDecodingToolbox) - directory multivariate
- Run decoder and extract decision values (= neural values)
  - decoding_get_neural_values.m
  - extract_neural_values.m
- Then convert single trial data from .mat files to .csv for python compatibility
  - convert_single_toCSV.m
- Then run python model comparison script (VPR / bifurcation score / AUC prediction + treeBh correction all in one)
  - model_comp_prediction_NOvpr.ipynb
  - (old version = model_comp_prediction_vpr.ipynb - with VPR penalty)






