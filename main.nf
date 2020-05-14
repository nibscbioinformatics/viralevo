#!/usr/bin/env nextflow
/*
========================================================================================
                         nibscbioinformatics/viralevo
========================================================================================
 nibscbioinformatics/viralevo Analysis Pipeline.
 #### Homepage / Documentation
 https://github.com/nibscbioinformatics/viralevo
----------------------------------------------------------------------------------------
*/

def helpMessage() {
    // TODO nf-core: Add to this help message with new command line parameters
    log.info nfcoreHeader()
    log.info"""

    Usage:

    The typical command for running the pipeline is as follows:

    nextflow run nibscbioinformatics/viralevo --input 'path/to/samples.tsv' -profile docker

    Mandatory arguments:
      --input [file]                TSV file indicating samples and corresponding reads
      -profile [str]                Configuration profile to use. Can use multiple (comma separated)
                                    Available: conda, docker, singularity, test, awsbatch, <institute> and more

    Options:
      --genome [str]                  Name of iGenomes reference
      --single_end [bool]             Specifies that the input is single-end reads

    References                        If not specified in the configuration file or you wish to overwrite any of the references
      --fasta [file]                  Path to fasta reference

    Other options:
      --outdir [file]                 The output directory where the results will be saved
      --email [email]                 Set this parameter to your e-mail address to get a summary e-mail with details of the run sent to you when the workflow exits
      --email_on_fail [email]         Same as --email, except only send mail if the workflow is not successful
      --max_multiqc_email_size [str]  Theshold size for MultiQC report to be attached in notification email. If file generated by pipeline exceeds the threshold, it will not be attached (Default: 25MB)
      -name [str]                     Name for the pipeline run. If not specified, Nextflow will automatically generate a random mnemonic

    AWSBatch options:
      --awsqueue [str]                The AWSBatch JobQueue that needs to be set when running on AWSBatch
      --awsregion [str]               The AWS Region for your AWS Batch job to run on
      --awscli [str]                  Path to the AWS CLI tool
    """.stripIndent()
}

// Show help message
if (params.help) {
    helpMessage()
    exit 0
}

/*
 * SET UP CONFIGURATION VARIABLES
 */

// Check if genome exists in the config file
if (params.genomes && params.genome && !params.genomes.containsKey(params.genome)) {
    exit 1, "The provided genome '${params.genome}' is not available in the iGenomes file. Currently the available genomes are ${params.genomes.keySet().join(", ")}"
}

// TODO nf-core: Add any reference files that are needed
// Configurable reference genomes
//
// NOTE - THIS IS NOT USED IN THIS PIPELINE, EXAMPLE ONLY
// If you want to use the channel below in a process, define the following:
//   input:
//   file fasta from ch_fasta
//
params.fasta = params.genome ? params.genomes[ params.genome ].fasta ?: false : false
if (params.fasta) { ch_fasta = file(params.fasta, checkIfExists: true) }

// Has the run name been specified by the user?
//  this has the bonus effect of catching both -name and --name
custom_runName = params.name
if (!(workflow.runName ==~ /[a-z]+_[a-z]+/)) {
    custom_runName = workflow.runName
}

if (workflow.profile.contains('awsbatch')) {
    // AWSBatch sanity checking
    if (!params.awsqueue || !params.awsregion) exit 1, "Specify correct --awsqueue and --awsregion parameters on AWSBatch!"
    // Check outdir paths to be S3 buckets if running on AWSBatch
    // related: https://github.com/nextflow-io/nextflow/issues/813
    if (!params.outdir.startsWith('s3:')) exit 1, "Outdir not on S3 - specify S3 Bucket to run on AWSBatch!"
    // Prevent trace files to be stored on S3 since S3 does not support rolling files.
    if (params.tracedir.startsWith('s3:')) exit 1, "Specify a local tracedir or run without trace! S3 cannot be used for tracefiles."
}

// Stage config files
ch_multiqc_config = file("$baseDir/assets/multiqc_config.yaml", checkIfExists: true)
ch_multiqc_custom_config = params.multiqc_config ? Channel.fromPath(params.multiqc_config, checkIfExists: true) : Channel.empty()
ch_output_docs = file("$baseDir/docs/output.md", checkIfExists: true)

/* ############################################
 * Create a channel for input read files
 * ############################################
 */

inputSample = Channel.empty()
if (params.input) {
  tsvFile = file(params.input)
  inputSample = readInputFile(tsvFile)
}
else {
  log.info "No TSV file"
  exit 1, 'No sample were defined, see --help'
}






// Header log info
log.info nfcoreHeader()
def summary = [:]
if (workflow.revision) summary['Pipeline Release'] = workflow.revision
summary['Run Name']         = custom_runName ?: workflow.runName
// TODO nf-core: Report custom parameters here
summary['Reads']            = params.reads
summary['Fasta Ref']        = params.fasta
summary['Data Type']        = params.single_end ? 'Single-End' : 'Paired-End'
summary['Max Resources']    = "$params.max_memory memory, $params.max_cpus cpus, $params.max_time time per job"
if (workflow.containerEngine) summary['Container'] = "$workflow.containerEngine - $workflow.container"
summary['Output dir']       = params.outdir
summary['Launch dir']       = workflow.launchDir
summary['Working dir']      = workflow.workDir
summary['Script dir']       = workflow.projectDir
summary['User']             = workflow.userName
if (workflow.profile.contains('awsbatch')) {
    summary['AWS Region']   = params.awsregion
    summary['AWS Queue']    = params.awsqueue
    summary['AWS CLI']      = params.awscli
}
summary['Config Profile'] = workflow.profile
if (params.config_profile_description) summary['Config Description'] = params.config_profile_description
if (params.config_profile_contact)     summary['Config Contact']     = params.config_profile_contact
if (params.config_profile_url)         summary['Config URL']         = params.config_profile_url
if (params.email || params.email_on_fail) {
    summary['E-mail Address']    = params.email
    summary['E-mail on failure'] = params.email_on_fail
    summary['MultiQC maxsize']   = params.max_multiqc_email_size
}
log.info summary.collect { k,v -> "${k.padRight(18)}: $v" }.join("\n")
log.info "-\033[2m--------------------------------------------------\033[0m-"

// Check the hostnames against configured profiles
checkHostname()

Channel.from(summary.collect{ [it.key, it.value] })
    .map { k,v -> "<dt>$k</dt><dd><samp>${v ?: '<span style=\"color:#999999;\">N/A</a>'}</samp></dd>" }
    .reduce { a, b -> return [a, b].join("\n            ") }
    .map { x -> """
    id: 'nibscbioinformatics-viralevo-summary'
    description: " - this information is collected when the pipeline is started."
    section_name: 'nibscbioinformatics/viralevo Workflow Summary'
    section_href: 'https://github.com/nibscbioinformatics/viralevo'
    plot_type: 'html'
    data: |
        <dl class=\"dl-horizontal\">
            $x
        </dl>
    """.stripIndent() }
    .set { ch_workflow_summary }

/*
 * Parse software version numbers
 */
process get_software_versions {
    publishDir "${params.outdir}/pipeline_info", mode: 'copy',
        saveAs: { filename ->
                      if (filename.indexOf(".csv") > 0) filename
                      else null
                }

    output:
    file 'software_versions_mqc.yaml' into ch_software_versions_yaml
    file "software_versions.csv"

    script:
    // TODO nf-core: Get all tools to print their version number here
    """
    echo $workflow.manifest.version > v_pipeline.txt
    echo $workflow.nextflow.version > v_nextflow.txt
    fastqc --version > v_fastqc.txt
    multiqc --version > v_multiqc.txt
    scrape_software_versions.py &> software_versions_mqc.yaml
    """
}

/*
 * STEP 1 - FastQC
 */
process fastqc {
    tag "$name"
    label 'process_medium'
    publishDir "${params.outdir}/fastqc", mode: 'copy',
        saveAs: { filename ->
                      filename.indexOf(".zip") > 0 ? "zips/$filename" : "$filename"
                }

    input:
    set val(name), file(reads) from ch_read_files_fastqc

    output:
    file "*_fastqc.{zip,html}" into ch_fastqc_results

    script:
    """
    fastqc --quiet --threads $task.cpus $reads
    """
}

/*
 * STEP 2 - MultiQC
 */
process multiqc {
    publishDir "${params.outdir}/MultiQC", mode: 'copy'

    input:
    file (multiqc_config) from ch_multiqc_config
    file (mqc_custom_config) from ch_multiqc_custom_config.collect().ifEmpty([])
    // TODO nf-core: Add in log files from your new processes for MultiQC to find!
    file ('fastqc/*') from ch_fastqc_results.collect().ifEmpty([])
    file ('software_versions/*') from ch_software_versions_yaml.collect()
    file workflow_summary from ch_workflow_summary.collectFile(name: "workflow_summary_mqc.yaml")

    output:
    file "*multiqc_report.html" into ch_multiqc_report
    file "*_data"
    file "multiqc_plots"

    script:
    rtitle = custom_runName ? "--title \"$custom_runName\"" : ''
    rfilename = custom_runName ? "--filename " + custom_runName.replaceAll('\\W','_').replaceAll('_+','_') + "_multiqc_report" : ''
    custom_config_file = params.multiqc_config ? "--config $mqc_custom_config" : ''
    // TODO nf-core: Specify which MultiQC modules to use with -m for a faster run time
    """
    multiqc -f $rtitle $rfilename $custom_config_file .
    """
}

/*
 * STEP 3 - Output Description HTML
 */
process output_documentation {
    publishDir "${params.outdir}/pipeline_info", mode: 'copy'

    input:
    file output_docs from ch_output_docs

    output:
    file "results_description.html"

    script:
    """
    markdown_to_html.py $output_docs -o results_description.html
    """
}

//START OF NIBSC CUTADAPT-BWA-LOFREQ PIPELINE

process docutadapt {
  publishDir "$params.outdir/alignments", mode: "copy"
  cpus 1
  queue 'WORK'
  time '12h'
  memory '4 GB'

  input:
  set ( sampleprefix, file(samples) ) from ch_read_files_trimming

  output:
  set ( sampleprefix, file("${sampleprefix}_L001_R1_001.trimmed.fastq.gz"), file("${sampleprefix}_L001_R2_001.trimmed.fastq.gz") ) into (trimmingoutput1, trimmingoutput2)
  file("${sampleprefix}.trim.out") into trimouts

  script:
  """
  module load CUTAdapt/latest
  cutadapt -a file:${params.adapterfile} -A file:${params.adapterfile} -g file:${params.adapterfile} -G file:${params.adapterfile} -o ${sampleprefix}_L001_R1_001.trimmed.fastq.gz -p ${sampleprefix}_L001_R2_001.trimmed.fastq.gz ${samples[0]} ${samples[1]} -q 30,30 --minimum-length 50 --times 40 -e 0.1 --max-n 0 > ${sampleprefix}.trim.out 2> ${sampleprefix}.trim.err
  """
}

process dotrimlog {
  publishDir "$params.outdir/analysis", mode: "copy"
  cpus 1
  queue 'WORK'
  time '12h'
  memory '4 GB'

  input:
  file "logdir/*" from trimouts.toSortedList()

  output:
  file("trimming-summary.csv") into trimlogend

  script:
  """
  module load anaconda/Py2/python2
  python $HOME/CODE/core/utilities/logger.py logdir trimming-summary.csv cutadapt
  """
}

process doalignment {
  publishDir "$params.outdir/alignments", mode: "copy"
  cpus 32
  queue 'WORK'
  time '12h'
  memory '10 GB'

  input:
  set (sampleprefix, file(forwardtrimmed), file(reversetrimmed)) from trimmingoutput1
  file refs from ref1.first()

  output:
  set (sampleprefix, file("${sampleprefix}.unsorted.sam") ) into samfile

  script:
  """
  module load BWA/latest
  bwa mem -t ${params.cpus} -R '@RG\\tID:${sampleprefix}\\tSM:${sampleprefix}\\tPL:Illumina' ${refs}/${params.referencefile} ${forwardtrimmed} ${reversetrimmed} > ${sampleprefix}.unsorted.sam
  """
}

process sorttobam {
  publishDir "$params.outdir/alignments", mode: "copy"
  cpus 1
  queue 'WORK'
  time '12h'
  memory '24 GB'

  input:
  set ( sampleprefix, file(unsortedsam) ) from samfile

  output:
  set ( sampleprefix, file("${sampleprefix}.sorted.bam") ) into sortedbam

  """
  module load SAMTools/latest
  samtools sort -o ${sampleprefix}.sorted.bam -O BAM -@ ${params.cpus} ${unsortedsam}
  """
}

process markduplicates {
  publishDir "$params.outdir/alignments", mode: "copy"
  cpus 1
  queue 'WORK'
  time '12h'
  memory '24 GB'

  input:
  set ( sampleprefix, file(sortedbamfile) ) from sortedbam

  output:
  set ( sampleprefix, file("${sampleprefix}.marked.bam") ) into markedbam

  """
  module load GATK/4.1.3.0
  gatk MarkDuplicates -I $sortedbamfile -M ${sampleprefix}.metrics.txt -O ${sampleprefix}.marked.bam
  """
}

process indelqual {
  publishDir "$params.outdir/alignments", mode: "copy"
  cpus 1
  queue 'WORK'
  time '12h'
  memory '24 GB'

  input:
  set ( sampleprefix, file(markedbamfile) ) from markedbam
  file refs from ref3.first()

  output:
  set ( sampleprefix, file("${sampleprefix}.indelqual.bam") ) into (indelqualforindex, indelqualforcall)

  """
  module load LoFREQ/latest
  lofreq indelqual --dindel -f ${refs}/${params.referencefile} -o ${sampleprefix}.indelqual.bam $markedbamfile
  """
}

process samtoolsindex {
  publishDir "$params.outdir/alignments", mode: "copy"
  cpus 1
  queue 'WORK'
  time '12h'
  memory '24 GB'

  input:
  set ( sampleprefix, file(indelqualfile) ) from indelqualforindex

  output:
  set ( sampleprefix, file("${indelqualfile}.bai") ) into samindex
  file("${sampleprefix}.flagstat.out") into flagstatouts

  """
  module load SAMTools/latest
  samtools index $indelqualfile
  samtools flagstat $indelqualfile > ${sampleprefix}.flagstat.out
  """
}

process doalignmentlog {
  publishDir "$params.outdir/analysis", mode: "copy"
  cpus 1
  queue 'WORK'
  time '12h'
  memory '4 GB'

  input:
  file "logdir/*" from flagstatouts.toSortedList()

  output:
  file("alignment-summary.csv") into alignmentlogend

  script:
  """
  module load anaconda/Py2/python2
  python $HOME/CODE/core/utilities/logger.py logdir alignment-summary.csv flagstat
  """
}

forcall = indelqualforcall.join(samindex)
forcall.into {
  forcall1
  forcall2
}

process varcall {
  publishDir "$params.outdir/analysis", mode: "copy"
  cpus 1
  queue 'WORK'
  time '12h'
  memory '24 GB'

  input:
  set ( sampleprefix, file(indelqualfile), file(samindexfile) ) from forcall1
  file refs from ref4.first()

  output:
  set ( sampleprefix, file("${sampleprefix}.lofreq.vcf") ) into finishedcalls

  """
  module load LoFREQ/latest
  lofreq call -f ${refs}/${params.referencefile} -o ${sampleprefix}.lofreq.vcf --call-indels $indelqualfile
  """
}

process dodepth {
  publishDir "$params.outdir/alignments", mode: "copy"
  cpus 1
  queue 'WORK'
  time '12h'
  memory '50 GB'

  input:
  set ( sampleprefix, file(indelqualfile), file(samindexfile) ) from forcall2

  output:
  set ( sampleprefix, file("${sampleprefix}.samtools.depth") ) into samdepthout

  """
  module load SAMTools/latest
  samtools depth -aa $indelqualfile > ${sampleprefix}.samtools.depth
  """
}

process makevartable {
  publishDir "$params.outdir/analysis", mode: "copy"
  cpus 1
  queue 'WORK'
  time '12h'
  memory '24 GB'

  input:
  set ( sampleprefix, file(lofreqout) ) from finishedcalls

  output:
  set ( sampleprefix, file("${sampleprefix}-variants.csv") ) into nicetable

  """
  module load anaconda/Py2/python2
  python $HOME/CODE/core/utilities/tablefromvcf.py $lofreqout ${sampleprefix}-variants.csv
  """
}

//END OF NIBSC CUTADAPT-BWA-LOFREQ PIPELINE



/*
 * Completion e-mail notification
 */
workflow.onComplete {

    // Set up the e-mail variables
    def subject = "[nibscbioinformatics/viralevo] Successful: $workflow.runName"
    if (!workflow.success) {
        subject = "[nibscbioinformatics/viralevo] FAILED: $workflow.runName"
    }
    def email_fields = [:]
    email_fields['version'] = workflow.manifest.version
    email_fields['runName'] = custom_runName ?: workflow.runName
    email_fields['success'] = workflow.success
    email_fields['dateComplete'] = workflow.complete
    email_fields['duration'] = workflow.duration
    email_fields['exitStatus'] = workflow.exitStatus
    email_fields['errorMessage'] = (workflow.errorMessage ?: 'None')
    email_fields['errorReport'] = (workflow.errorReport ?: 'None')
    email_fields['commandLine'] = workflow.commandLine
    email_fields['projectDir'] = workflow.projectDir
    email_fields['summary'] = summary
    email_fields['summary']['Date Started'] = workflow.start
    email_fields['summary']['Date Completed'] = workflow.complete
    email_fields['summary']['Pipeline script file path'] = workflow.scriptFile
    email_fields['summary']['Pipeline script hash ID'] = workflow.scriptId
    if (workflow.repository) email_fields['summary']['Pipeline repository Git URL'] = workflow.repository
    if (workflow.commitId) email_fields['summary']['Pipeline repository Git Commit'] = workflow.commitId
    if (workflow.revision) email_fields['summary']['Pipeline Git branch/tag'] = workflow.revision
    email_fields['summary']['Nextflow Version'] = workflow.nextflow.version
    email_fields['summary']['Nextflow Build'] = workflow.nextflow.build
    email_fields['summary']['Nextflow Compile Timestamp'] = workflow.nextflow.timestamp

    // TODO nf-core: If not using MultiQC, strip out this code (including params.max_multiqc_email_size)
    // On success try attach the multiqc report
    def mqc_report = null
    try {
        if (workflow.success) {
            mqc_report = ch_multiqc_report.getVal()
            if (mqc_report.getClass() == ArrayList) {
                log.warn "[nibscbioinformatics/viralevo] Found multiple reports from process 'multiqc', will use only one"
                mqc_report = mqc_report[0]
            }
        }
    } catch (all) {
        log.warn "[nibscbioinformatics/viralevo] Could not attach MultiQC report to summary email"
    }

    // Check if we are only sending emails on failure
    email_address = params.email
    if (!params.email && params.email_on_fail && !workflow.success) {
        email_address = params.email_on_fail
    }

    // Render the TXT template
    def engine = new groovy.text.GStringTemplateEngine()
    def tf = new File("$baseDir/assets/email_template.txt")
    def txt_template = engine.createTemplate(tf).make(email_fields)
    def email_txt = txt_template.toString()

    // Render the HTML template
    def hf = new File("$baseDir/assets/email_template.html")
    def html_template = engine.createTemplate(hf).make(email_fields)
    def email_html = html_template.toString()

    // Render the sendmail template
    def smail_fields = [ email: email_address, subject: subject, email_txt: email_txt, email_html: email_html, baseDir: "$baseDir", mqcFile: mqc_report, mqcMaxSize: params.max_multiqc_email_size.toBytes() ]
    def sf = new File("$baseDir/assets/sendmail_template.txt")
    def sendmail_template = engine.createTemplate(sf).make(smail_fields)
    def sendmail_html = sendmail_template.toString()

    // Send the HTML e-mail
    if (email_address) {
        try {
            if (params.plaintext_email) { throw GroovyException('Send plaintext e-mail, not HTML') }
            // Try to send HTML e-mail using sendmail
            [ 'sendmail', '-t' ].execute() << sendmail_html
            log.info "[nibscbioinformatics/viralevo] Sent summary e-mail to $email_address (sendmail)"
        } catch (all) {
            // Catch failures and try with plaintext
            [ 'mail', '-s', subject, email_address ].execute() << email_txt
            log.info "[nibscbioinformatics/viralevo] Sent summary e-mail to $email_address (mail)"
        }
    }

    // Write summary e-mail HTML to a file
    def output_d = new File("${params.outdir}/pipeline_info/")
    if (!output_d.exists()) {
        output_d.mkdirs()
    }
    def output_hf = new File(output_d, "pipeline_report.html")
    output_hf.withWriter { w -> w << email_html }
    def output_tf = new File(output_d, "pipeline_report.txt")
    output_tf.withWriter { w -> w << email_txt }

    c_green = params.monochrome_logs ? '' : "\033[0;32m";
    c_purple = params.monochrome_logs ? '' : "\033[0;35m";
    c_red = params.monochrome_logs ? '' : "\033[0;31m";
    c_reset = params.monochrome_logs ? '' : "\033[0m";

    if (workflow.stats.ignoredCount > 0 && workflow.success) {
        log.info "-${c_purple}Warning, pipeline completed, but with errored process(es) ${c_reset}-"
        log.info "-${c_red}Number of ignored errored process(es) : ${workflow.stats.ignoredCount} ${c_reset}-"
        log.info "-${c_green}Number of successfully ran process(es) : ${workflow.stats.succeedCount} ${c_reset}-"
    }

    if (workflow.success) {
        log.info "-${c_purple}[nibscbioinformatics/viralevo]${c_green} Pipeline completed successfully${c_reset}-"
    } else {
        checkHostname()
        log.info "-${c_purple}[nibscbioinformatics/viralevo]${c_red} Pipeline completed with errors${c_reset}-"
    }

}


def nfcoreHeader() {
    // Log colors ANSI codes
    c_black = params.monochrome_logs ? '' : "\033[0;30m";
    c_blue = params.monochrome_logs ? '' : "\033[0;34m";
    c_cyan = params.monochrome_logs ? '' : "\033[0;36m";
    c_dim = params.monochrome_logs ? '' : "\033[2m";
    c_green = params.monochrome_logs ? '' : "\033[0;32m";
    c_purple = params.monochrome_logs ? '' : "\033[0;35m";
    c_reset = params.monochrome_logs ? '' : "\033[0m";
    c_white = params.monochrome_logs ? '' : "\033[0;37m";
    c_yellow = params.monochrome_logs ? '' : "\033[0;33m";

    return """    -${c_dim}--------------------------------------------------${c_reset}-
                                            ${c_green},--.${c_black}/${c_green},-.${c_reset}
    ${c_blue}        ___     __   __   __   ___     ${c_green}/,-._.--~\'${c_reset}
    ${c_blue}  |\\ | |__  __ /  ` /  \\ |__) |__         ${c_yellow}}  {${c_reset}
    ${c_blue}  | \\| |       \\__, \\__/ |  \\ |___     ${c_green}\\`-._,-`-,${c_reset}
                                            ${c_green}`._,._,\'${c_reset}
    ${c_purple}  nibscbioinformatics/viralevo v${workflow.manifest.version}${c_reset}
    -${c_dim}--------------------------------------------------${c_reset}-
    """.stripIndent()
}

def checkHostname() {
    def c_reset = params.monochrome_logs ? '' : "\033[0m"
    def c_white = params.monochrome_logs ? '' : "\033[0;37m"
    def c_red = params.monochrome_logs ? '' : "\033[1;91m"
    def c_yellow_bold = params.monochrome_logs ? '' : "\033[1;93m"
    if (params.hostnames) {
        def hostname = "hostname".execute().text.trim()
        params.hostnames.each { prof, hnames ->
            hnames.each { hname ->
                if (hostname.contains(hname) && !workflow.profile.contains(prof)) {
                    log.error "====================================================\n" +
                            "  ${c_red}WARNING!${c_reset} You are running with `-profile $workflow.profile`\n" +
                            "  but your machine hostname is ${c_white}'$hostname'${c_reset}\n" +
                            "  ${c_yellow_bold}It's highly recommended that you use `-profile $prof${c_reset}`\n" +
                            "============================================================"
                }
            }
        }
    }
}


// ############## UTILITIES AND SAMPLE LOADING ######################

def readInputFile(tsvFile) {
    Channel.from(tsvFile)
        .splitCsv(sep: '\t')
        .map { row ->
            def idSample  = row[0]
            def file1      = returnFile(row[2])
            def file2      = "null"
            if (hasExtension(file1, "fastq.gz") || hasExtension(file1, "fq.gz")) {
                checkNumberOfItem(row, 3)
                file2 = returnFile(row[2])
                if (!hasExtension(file2, "fastq.gz") && !hasExtension(file2, "fq.gz")) exit 1, "File: ${file2} has the wrong extension. See --help for more information"
            }
            // else if (hasExtension(file1, "bam")) checkNumberOfItem(row, 5)
            // here we only use this function for fastq inputs and therefore we suppress bam files
            else "No recognisable extension for input file: ${file1}"
            [idSample, file1, file2]
        }
}

// #### SAREK FUNCTIONS #########################
def checkNumberOfItem(row, number) {
    if (row.size() != number) exit 1, "Malformed row in TSV file: ${row}, see --help for more information"
    return true
}

def hasExtension(it, extension) {
    it.toString().toLowerCase().endsWith(extension.toLowerCase())
}

// Return file if it exists
def returnFile(it) {
    if (!file(it).exists()) exit 1, "Missing file in TSV file: ${it}, see --help for more information"
    return file(it)
}

// Return status [0,1]
// 0 == Control, 1 == Case
def returnStatus(it) {
    if (!(it in [0, 1])) exit 1, "Status is not recognized in TSV file: ${it}, see --help for more information"
    return it
}

// ############### OTHER UTILS ##########################

// Example usage: defaultIfInexistent({myVar}, "default")
def defaultIfInexistent(varNameExpr, defaultValue) {
    try {
        varNameExpr()
    } catch (exc) {
        defaultValue
    }
}
