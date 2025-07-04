/**
 * Results Management Utilities for Nextflow Pipelines
 * Provides functions for creating organized results directories and managing run metadata
 */

import java.text.SimpleDateFormat
import java.nio.file.Files
import java.nio.file.Paths
import groovy.json.JsonBuilder
import groovy.json.JsonSlurper

class ResultsManager {
    
    static String createResultsDirectory(Map params) {
        def workflowType = params.workflow_type ?: 'analysis'
        def projectName = params.project_name ?: 'pipeline'
        def baseDir = params.base_results_dir ?: 'results'
        
        def dateFormat = new SimpleDateFormat('yyyy-MM-dd')
        def timeFormat = new SimpleDateFormat('HHmmss')
        def now = new Date()
        
        def runDate = dateFormat.format(now)
        def runTime = timeFormat.format(now)
        
        // Create results directory path
        def resultsDir = "${baseDir}/${runDate}/${workflowType}/${runTime}"
        
        // Create directory structure based on workflow type
        def subdirs = getSubdirectories(workflowType)
        subdirs.each { subdir ->
            Files.createDirectories(Paths.get("${resultsDir}/${subdir}"))
        }
        
        // Create run metadata
        createRunMetadata(resultsDir, workflowType, projectName, params)
        
        // Update latest symlink
        updateLatestSymlink(baseDir, workflowType, runDate, runTime)
        
        return resultsDir
    }
    
    static List<String> getSubdirectories(String workflowType) {
        switch (workflowType) {
            case 'hyperopt':
                return [
                    '01_data_preparation',
                    '02_optimization/trials',
                    '03_validation',
                    '04_reports',
                    'pipeline_info'
                ]
            case 'training':
                return [
                    '01_preprocessing',
                    '02_model_training',
                    '03_evaluation',
                    '04_reports',
                    'pipeline_info'
                ]
            case 'inference':
                return [
                    '01_input_processing',
                    '02_predictions',
                    '03_quality_control',
                    '04_reports',
                    'pipeline_info'
                ]
            default:
                return [
                    '01_preprocessing',
                    '02_analysis',
                    '03_reports',
                    'pipeline_info'
                ]
        }
    }
    
    static void createRunMetadata(String resultsDir, String workflowType, String projectName, Map params) {
        def dateFormat = new SimpleDateFormat('yyyy-MM-dd')
        def timeFormat = new SimpleDateFormat('HHmmss')
        def isoFormat = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'")
        def now = new Date()
        
        def runDate = dateFormat.format(now)
        def runTime = timeFormat.format(now)
        def runId = "${workflowType}_${runDate.replaceAll('-', '')}_${runTime}"
        
        // Get git information if available
        def gitCommit = getGitCommit()
        def gitBranch = getGitBranch()
        
        def runInfo = [
            run_id: runId,
            project_name: projectName,
            workflow_type: workflowType,
            start_time: isoFormat.format(now),
            run_date: runDate,
            run_time: runTime,
            status: 'running',
            created_by: System.getProperty('user.name'),
            hostname: InetAddress.getLocalHost().getHostName(),
            working_directory: System.getProperty('user.dir'),
            git_commit: gitCommit,
            git_branch: gitBranch,
            nextflow_version: nextflow.Nextflow.version.toString(),
            parameters: filterParameters(params),
            results_path: resultsDir,
            compute_environment: 'local'
        ]
        
        def jsonBuilder = new JsonBuilder(runInfo)
        def metadataFile = new File("${resultsDir}/run_info.json")
        metadataFile.text = jsonBuilder.toPrettyString()
    }
    
    static Map filterParameters(Map params) {
        // Filter out internal Nextflow parameters
        return params.findAll { key, value ->
            !key.startsWith('_') && 
            !key.in(['workflow', 'baseDir', 'workDir', 'projectDir', 'launchDir'])
        }
    }
    
    static String getGitCommit() {
        try {
            def proc = ['git', 'rev-parse', 'HEAD'].execute()
            proc.waitFor()
            return proc.exitValue() == 0 ? proc.text.trim() : 'unknown'
        } catch (Exception e) {
            return 'unknown'
        }
    }
    
    static String getGitBranch() {
        try {
            def proc = ['git', 'branch', '--show-current'].execute()
            proc.waitFor()
            return proc.exitValue() == 0 ? proc.text.trim() : 'unknown'
        } catch (Exception e) {
            return 'unknown'
        }
    }
    
    static void updateLatestSymlink(String baseDir, String workflowType, String runDate, String runTime) {
        def latestDir = new File("${baseDir}/latest")
        if (!latestDir.exists()) {
            latestDir.mkdirs()
        }
        
        def symlinkPath = "${baseDir}/latest/${workflowType}"
        def targetPath = "../${runDate}/${workflowType}/${runTime}"
        
        // Remove existing symlink if it exists
        def existingLink = new File(symlinkPath)
        if (existingLink.exists()) {
            existingLink.delete()
        }
        
        // Create new symlink
        try {
            Files.createSymbolicLink(Paths.get(symlinkPath), Paths.get(targetPath))
        } catch (Exception e) {
            println "Warning: Could not create symlink: ${e.message}"
        }
    }
    
    static void updateRunStatus(String resultsDir, String status) {
        def metadataFile = new File("${resultsDir}/run_info.json")
        if (metadataFile.exists()) {
            try {
                def jsonSlurper = new JsonSlurper()
                def runInfo = jsonSlurper.parse(metadataFile)
                
                runInfo.status = status
                runInfo.end_time = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'").format(new Date())
                
                def jsonBuilder = new JsonBuilder(runInfo)
                metadataFile.text = jsonBuilder.toPrettyString()
            } catch (Exception e) {
                println "Warning: Could not update run status: ${e.message}"
            }
        }
    }
    
    static Map getPublishDirConfig(String resultsDir, String workflowType) {
        def subdirs = getSubdirectories(workflowType)
        def publishDirs = []
        
        // Create publish directory configurations
        switch (workflowType) {
            case 'hyperopt':
                publishDirs = [
                    [path: "${resultsDir}/01_data_preparation", mode: 'copy', pattern: '*_qc.*'],
                    [path: "${resultsDir}/02_optimization/trials", mode: 'copy', pattern: 'trial_*'],
                    [path: "${resultsDir}/02_optimization", mode: 'copy', pattern: 'best_parameters.*'],
                    [path: "${resultsDir}/02_optimization", mode: 'copy', pattern: 'optimization_history.*'],
                    [path: "${resultsDir}/03_validation", mode: 'copy', pattern: '*_validation.*'],
                    [path: "${resultsDir}/04_reports", mode: 'copy', pattern: '*.html'],
                    [path: "${resultsDir}/04_reports", mode: 'copy', pattern: '*.png'],
                    [path: "${resultsDir}/pipeline_info", mode: 'copy', pattern: '.command.*']
                ]
                break
            case 'training':
                publishDirs = [
                    [path: "${resultsDir}/01_preprocessing", mode: 'copy', pattern: '*_preprocessed.*'],
                    [path: "${resultsDir}/02_model_training", mode: 'copy', pattern: '*_model.*'],
                    [path: "${resultsDir}/02_model_training", mode: 'copy', pattern: 'training_metrics.*'],
                    [path: "${resultsDir}/03_evaluation", mode: 'copy', pattern: '*_evaluation.*'],
                    [path: "${resultsDir}/04_reports", mode: 'copy', pattern: '*.html'],
                    [path: "${resultsDir}/pipeline_info", mode: 'copy', pattern: '.command.*']
                ]
                break
            case 'inference':
                publishDirs = [
                    [path: "${resultsDir}/01_input_processing", mode: 'copy', pattern: '*_processed.*'],
                    [path: "${resultsDir}/02_predictions", mode: 'copy', pattern: '*_predictions.*'],
                    [path: "${resultsDir}/03_quality_control", mode: 'copy', pattern: '*_qc.*'],
                    [path: "${resultsDir}/04_reports", mode: 'copy', pattern: '*.html'],
                    [path: "${resultsDir}/pipeline_info", mode: 'copy', pattern: '.command.*']
                ]
                break
            default:
                publishDirs = [
                    [path: "${resultsDir}/01_preprocessing", mode: 'copy', pattern: '*_qc.*'],
                    [path: "${resultsDir}/02_analysis", mode: 'copy', pattern: '*_results.*'],
                    [path: "${resultsDir}/03_reports", mode: 'copy', pattern: '*.html'],
                    [path: "${resultsDir}/pipeline_info", mode: 'copy', pattern: '.command.*']
                ]
        }
        
        return [publishDir: publishDirs]
    }
}
