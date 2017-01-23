pipelineJob("Build platform docker image") {
  description("<b><span style='color:red'>DO NOT EDIT HERE!</span></b>")

  concurrentBuild(false)

  parameters {
    stringParam('imageName', 'plf', 'Image name')
    stringParam('plfDownloadUrl','https://repository.exoplatform.org/service/local/artifact/maven/redirect?g=org.exoplatform.platform.distributions&a=plf-community-tomcat-standalone&v=${plfFullVersion}&r=exo-snapshots&e=zip', 'The full url where to download the platform binary')
    stringParam('plfFullVersion', '4.5.x-SNAPSHOT', 'The full platform version to test')
    stringParam('plfMinorVersion', '4.5', 'The platform version <major.minor> TODO to compute from full version')
    choiceParam('database', ['mysql'])
    choiceParam('elasticsearch', ['es'])
  }

  environmentVariables {
    keepSystemVariables(true)
    keepBuildVariables(true)
  }

  scm {
    git('https://github.com/exo-docker/exo', 'ITOP-3020')
  }

  wrappers {
    injectPasswords {
      injectGlobalPasswords()
    }
  }

  definition {
    cps {

      script('''
      def downloadUser
node('bench-plf') {
  stage('Cloning repo') {
    git branch: 'ITOP-3020', url: 'https://github.com/exo-docker/exo.git'
  }

  stage('Build plf image') {
    withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: 'benchDownloadUserPassword',
                usernameVariable: 'benchPlfDownloadUser', passwordVariable: 'benchPlfDownloadPassword']]) {
      sh "docker build  \
          -t ${imageName} \
          --build-arg DOWNLOAD_USER=${benchPlfDownloadUser}:${benchPlfDownloadPassword} \
          --build-arg EXO_VERSION_FULL=${plfFullVersion} \
          --build-arg EXO_MINOR_VERSION=${plfMinorVersion} \
          --build-arg EXO_DOWNLOAD='${plfDownloadUrl}' \
          .  \
          "
    }
  }

}
      ''')
    }
  }
}

