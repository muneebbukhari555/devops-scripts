#!groovy

/**
 *  Builds Jenkins backup Job and Push to Blob Storage.
 */
import groovy.json.JsonOutput
slackChannel = '#ci-cd'
podTemplate(
  containers: [ containerTemplate(
       name: 'jenkinsbackup', image: 'Dockerimage:tag',
       ttyEnabled: true, args: 'cat'
       )],
 
) {
  timeout(time: 1, unit: 'HOURS') {
    node(POD_LABEL) {
      container('jenkinsbackup') 
       {
          try
       {

          stage('latestbackup_Upload_to_azure_blob_storage')
      
        {
            container('jenkinsbackup')
        {
            withCredentials([azureServicePrincipal("SERVICE_PRINCIPLE")]) 
                {
            sh 'az login --service-principal -u $AZURE_CLIENT_ID -p $AZURE_CLIENT_SECRET -t $AZURE_TENANT_ID'
            sh 'az account set --subscription <sub_id>'

            sh """
                            echo 'you are now having deployment preparation :)'
                            apk add --update --no-cache unzip curl \
                            && curl -LO https://github.com/Azure/kubelogin/releases/download/v0.0.9/kubelogin-linux-amd64.zip \
                            && unzip kubelogin-linux-amd64.zip \
                            && mv ./bin/linux_amd64/kubelogin /usr/local/bin/kubelogin
            """
            sh "az aks get-credentials --resource-group rg-cs-dev-apps --name aks-eng-dev --admin"
            sh "export KUBECONFIG=/root/.kube/config"
            sh """
                            kubelogin convert-kubeconfig -l spn --client-id $AZURE_CLIENT_ID --client-secret $AZURE_CLIENT_SECRET
                            export AAD_SERVICE_PRINCIPAL_CLIENT_ID=$AZURE_CLIENT_ID
                            export AAD_SERVICE_PRINCIPAL_CLIENT_SECRET=$AZURE_CLIENT_SECRET
            """
          sh '''
                
                
            kubectl get pods  -n jenkins
            export JENKINS_POD_NAME=$(kubectl get pods -n jenkins | grep jenkins-0 | awk '{print $1}' | head -n 1)
            export JENKINS_AGENT_NAME=$(kubectl get pods -n jenkins | grep jenkinsbackup- | awk '{print $1}' | head -n 1)
            echo $JENKINS_POD_NAME
            echo $JENKINS_AGENT_NAME
            kubectl -n jenkins exec -ti $JENKINS_AGENT_NAME -- ls
            pwd
            
            kubectl -n jenkins exec -ti $JENKINS_POD_NAME -- ls  /var/jenkins_home/backup/  | grep gz | tail -1
            kubectl -n jenkins exec -ti $JENKINS_POD_NAME -- ls  /var/jenkins_home/backup/  | grep pbobj | tail -1
            export latest_backup_file_gz=$(kubectl -n jenkins exec -ti $JENKINS_POD_NAME -- ls  /var/jenkins_home/backup/  | grep gz | tail -1)
            export latest_backup_file_pbobj=$(kubectl -n jenkins exec -ti $JENKINS_POD_NAME -- ls  /var/jenkins_home/backup/  | grep pbobj | tail -1)
            echo ${latest_backup_file_gz} 
            echo ${latest_backup_file_pbobj}
            
            kubectl cp $JENKINS_POD_NAME:var/jenkins_home/backup/$latest_backup_file_gz  /tmp/$latest_backup_file_gz -n jenkins
            kubectl cp $JENKINS_POD_NAME:var/jenkins_home/backup/$latest_backup_file_pbobj  /tmp/$latest_backup_file_pbobj -n jenkins
            azcopy login --identity
            azcopy copy "/tmp/$latest_backup_file_gz" https://<sa_name>.blob.core.windows.net/jenkins-dev-backups
            azcopy copy "/tmp/$latest_backup_file_pbobj" https://<sa_name>.blob.core.windows.net/jenkins-dev-backups
            
            kubectl -n jenkins exec -ti $JENKINS_POD_NAME -- find /var/jenkins_home/backup -type f -mtime +2 -delete
            '''
          
        stage ('Slack notification')
        
        {
        slackSend(color: "good", channel: slackChannel, message: "Jenkins Backup SUCCESS for Core Services : https://portal.azure.com/#blade/Micro : ${env.JOB_NAME} ${env.BUILD_NUMBER}\nJenkins Url: ${env.BUILD_URL}")  
        bitbucketStatusNotify buildState: 'SUCCESS'
        }
        
        true
     }
        }
       }
       }
       catch(e) 
                 {
                    currentBuild.result == "FAILURE"
                    slackSend(color: "danger", channel: slackChannel, message: "Jenkins Backup failed for Core Services : ${env.JOB_NAME} ${env.BUILD_NUMBER}\nJenkins Url: ${env.BUILD_URL}")
                    bitbucketStatusNotify buildState: 'FAILED'
                 } 
                 finally {
                     cleanWs()
                 }
                 
                 
    }

    }
  }
}
