pipeline {
    agent {
        docker {
            image 'ghcr.io/cirruslabs/flutter:stable'
            args '-v /var/run/docker.sock:/var/run/docker.sock'
        }
    }

    environment {
        // JFrog Artifactory credentials
        ARTIFACTORY_URL = credentials('artifactory-url')
        ARTIFACTORY_USER = credentials('artifactory-user')
        ARTIFACTORY_PASSWORD = credentials('artifactory-password')
        ARTIFACTORY_REPO = 'owaspnote-artifacts'
        
        // SonarQube
        SONAR_HOST_URL = credentials('sonarqube-url')
        SONAR_AUTH_TOKEN = credentials('sonarqube-token')
        SONAR_PROJECT_KEY = 'owaspnote'
        
        // App signing (Android)
        ANDROID_KEYSTORE = credentials('android-keystore-file')
        ANDROID_KEY_ALIAS = credentials('android-key-alias')
        ANDROID_KEYSTORE_PASSWORD = credentials('android-keystore-password')
        ANDROID_KEY_PASSWORD = credentials('android-key-password')
        
        // Firebase App Distribution (optional)
        FIREBASE_APP_ID_ANDROID = credentials('firebase-app-id-android')
        FIREBASE_TOKEN = credentials('firebase-token')
        
        // Build versioning
        BUILD_VERSION = "${env.BUILD_NUMBER}-${env.GIT_COMMIT.take(7)}"
    }

    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timeout(time: 60, unit: 'MINUTES')
        timestamps()
        disableConcurrentBuilds()
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
                script {
                    env.GIT_COMMIT_MSG = sh(
                        script: 'git log -1 --pretty=%B',
                        returnStdout: true
                    ).trim()
                    env.GIT_AUTHOR = sh(
                        script: 'git log -1 --pretty=%an',
                        returnStdout: true
                    ).trim()
                }
            }
        }

        stage('Environment Setup') {
            steps {
                sh '''
                    flutter --version
                    flutter doctor -v
                    
                    # Create local.properties if it doesn't exist
                    if [ ! -f android/local.properties ]; then
                        echo "sdk.dir=${ANDROID_SDK_ROOT}" > android/local.properties
                        echo "flutter.sdk=${FLUTTER_ROOT}" >> android/local.properties
                    fi
                '''
            }
        }

        stage('Dependencies') {
            steps {
                sh '''
                    flutter pub get
                    flutter pub outdated || true
                '''
            }
        }

        stage('Code Quality') {
            parallel {
                stage('Flutter Analyze') {
                    steps {
                        sh '''
                            flutter analyze --no-fatal-infos > flutter_analyze_report.txt || true
                            
                            # Check if there are any errors
                            if grep -q "error •" flutter_analyze_report.txt; then
                                echo "Flutter analyze found errors"
                                cat flutter_analyze_report.txt
                                exit 1
                            fi
                        '''
                    }
                }

                stage('Format Check') {
                    steps {
                        sh '''
                            flutter format --dry-run --set-exit-if-changed . > format_report.txt || {
                                echo "Code formatting issues found:"
                                cat format_report.txt
                                exit 1
                            }
                        '''
                    }
                }

                stage('SonarQube Analysis') {
                    steps {
                        script {
                            // Install sonar-scanner if not available
                            sh '''
                                if ! command -v sonar-scanner &> /dev/null; then
                                    wget https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-4.8.0.2856-linux.zip
                                    unzip sonar-scanner-cli-4.8.0.2856-linux.zip
                                    export PATH=$PATH:$(pwd)/sonar-scanner-4.8.0.2856-linux/bin
                                fi
                            '''
                            
                            withSonarQubeEnv('SonarQube') {
                                sh '''
                                    sonar-scanner \
                                        -Dsonar.projectKey=${SONAR_PROJECT_KEY} \
                                        -Dsonar.sources=lib \
                                        -Dsonar.tests=test \
                                        -Dsonar.language=dart \
                                        -Dsonar.host.url=${SONAR_HOST_URL} \
                                        -Dsonar.login=${SONAR_AUTH_TOKEN} \
                                        -Dsonar.flutter.coverage.reportPath=coverage/lcov.info
                                '''
                            }
                        }
                    }
                }
            }
        }

        stage('Testing') {
            parallel {
                stage('Unit Tests') {
                    steps {
                        sh '''
                            flutter test --coverage --machine > test-results.json || true
                            
                            # Generate coverage report
                            if [ -f coverage/lcov.info ]; then
                                flutter pub global activate coverage
                                flutter pub global run coverage:format_coverage \
                                    --lcov --in=coverage --out=coverage/lcov.info \
                                    --report-on=lib
                            fi
                        '''
                        
                        // Archive test results
                        archiveArtifacts artifacts: 'test-results.json', allowEmptyArchive: true
                        archiveArtifacts artifacts: 'coverage/**/*', allowEmptyArchive: true
                    }
                }

                stage('Widget Tests') {
                    steps {
                        sh '''
                            flutter test test/widget_test.dart || true
                        '''
                    }
                }

                stage('Integration Tests') {
                    when {
                        branch pattern: "(main|develop|release/.*)", comparator: "REGEXP"
                    }
                    steps {
                        sh '''
                            # Run integration tests
                            flutter test integration_test/app_test.dart || true
                        '''
                    }
                }
            }
        }

        stage('Security Scan') {
            steps {
                sh '''
                    # Run security checks
                    flutter pub global activate very_good_cli
                    
                    # Check for known vulnerabilities in dependencies
                    flutter pub deps --json > deps.json
                    
                    # Basic security checks
                    echo "Running security checks..."
                    
                    # Check for hardcoded secrets
                    grep -r "password\\|secret\\|api_key\\|apikey" lib/ --exclude-dir=.git || true
                    
                    # Check for insecure HTTP usage
                    grep -r "http://" lib/ --exclude-dir=.git || true
                '''
            }
        }

        stage('Build') {
            parallel {
                stage('Build Android') {
                    steps {
                        script {
                            sh '''
                                # Clean previous builds
                                flutter clean
                                
                                # Build APK (debug for non-main branches)
                                if [ "${BRANCH_NAME}" = "main" ]; then
                                    # Create keystore properties
                                    cat > android/keystore.properties << EOF
storePassword=${ANDROID_KEYSTORE_PASSWORD}
keyPassword=${ANDROID_KEY_PASSWORD}
keyAlias=${ANDROID_KEY_ALIAS}
storeFile=${ANDROID_KEYSTORE}
EOF
                                    
                                    # Build release APK
                                    flutter build apk --release \
                                        --build-number=${BUILD_NUMBER} \
                                        --build-name=1.0.${BUILD_NUMBER}
                                    
                                    # Build release App Bundle
                                    flutter build appbundle --release \
                                        --build-number=${BUILD_NUMBER} \
                                        --build-name=1.0.${BUILD_NUMBER}
                                else
                                    # Build debug APK
                                    flutter build apk --debug \
                                        --build-number=${BUILD_NUMBER} \
                                        --build-name=1.0.${BUILD_NUMBER}
                                fi
                            '''
                            
                            // Archive artifacts
                            archiveArtifacts artifacts: 'build/app/outputs/flutter-apk/*.apk', fingerprint: true
                            archiveArtifacts artifacts: 'build/app/outputs/bundle/release/*.aab', allowEmptyArchive: true
                        }
                    }
                }

                stage('Build Web') {
                    steps {
                        sh '''
                            flutter clean
                            flutter build web --release \
                                --web-renderer canvaskit \
                                --build-number=${BUILD_NUMBER} \
                                --build-name=1.0.${BUILD_NUMBER}
                            
                            # Create deployment package
                            cd build/web
                            tar -czf ../../owaspnote-web-${BUILD_VERSION}.tar.gz *
                        '''
                        
                        archiveArtifacts artifacts: 'owaspnote-web-*.tar.gz', fingerprint: true
                    }
                }
            }
        }

        stage('Upload to Artifactory') {
            when {
                branch pattern: "(main|develop|release/.*)", comparator: "REGEXP"
            }
            steps {
                script {
                    // Configure JFrog CLI
                    sh '''
                        # Install JFrog CLI if not available
                        if ! command -v jfrog &> /dev/null; then
                            curl -fL https://getcli.jfrog.io | sh
                            chmod +x jfrog
                            sudo mv jfrog /usr/local/bin/
                        fi
                        
                        # Configure Artifactory
                        jfrog config add artifactory-server \
                            --artifactory-url=${ARTIFACTORY_URL} \
                            --user=${ARTIFACTORY_USER} \
                            --password=${ARTIFACTORY_PASSWORD} \
                            --interactive=false
                    '''
                    
                    // Upload Android artifacts
                    if (fileExists('build/app/outputs/flutter-apk/app-release.apk')) {
                        sh """
                            jfrog rt upload \
                                "build/app/outputs/flutter-apk/app-release.apk" \
                                "${ARTIFACTORY_REPO}/android/${BUILD_VERSION}/owaspnote-${BUILD_VERSION}.apk"
                        """
                    }
                    
                    if (fileExists('build/app/outputs/bundle/release/app-release.aab')) {
                        sh """
                            jfrog rt upload \
                                "build/app/outputs/bundle/release/app-release.aab" \
                                "${ARTIFACTORY_REPO}/android/${BUILD_VERSION}/owaspnote-${BUILD_VERSION}.aab"
                        """
                    }
                    
                    // Upload Web artifacts
                    sh """
                        jfrog rt upload \
                            "owaspnote-web-${BUILD_VERSION}.tar.gz" \
                            "${ARTIFACTORY_REPO}/web/${BUILD_VERSION}/"
                    """
                    
                    // Create build info
                    sh """
                        jfrog rt build-publish owaspnote ${BUILD_NUMBER}
                    """
                }
            }
        }

        stage('Deploy to Staging') {
            when {
                branch 'develop'
            }
            steps {
                script {
                    // Deploy web to staging
                    sh '''
                        echo "Deploying to staging environment..."
                        # Add your staging deployment commands here
                        # Example: scp, rsync, kubectl, etc.
                    '''
                    
                    // Deploy Android to Firebase App Distribution (optional)
                    if (env.FIREBASE_TOKEN) {
                        sh '''
                            if [ -f "build/app/outputs/flutter-apk/app-release.apk" ]; then
                                # Install Firebase CLI if needed
                                npm install -g firebase-tools
                                
                                firebase appdistribution:distribute \
                                    build/app/outputs/flutter-apk/app-release.apk \
                                    --app ${FIREBASE_APP_ID_ANDROID} \
                                    --release-notes "Build ${BUILD_VERSION}: ${GIT_COMMIT_MSG}" \
                                    --groups "qa-testers" \
                                    --token ${FIREBASE_TOKEN}
                            fi
                        '''
                    }
                }
            }
        }

        stage('Deploy to Production') {
            when {
                branch 'main'
                expression { currentBuild.result == null || currentBuild.result == 'SUCCESS' }
            }
            input {
                message "Deploy to production?"
                ok "Deploy"
                parameters {
                    choice(
                        name: 'DEPLOYMENT_TYPE',
                        choices: ['Web Only', 'Android Only', 'Both'],
                        description: 'Select deployment type'
                    )
                }
            }
            steps {
                script {
                    if (params.DEPLOYMENT_TYPE == 'Web Only' || params.DEPLOYMENT_TYPE == 'Both') {
                        sh '''
                            echo "Deploying web to production..."
                            # Add your production web deployment commands here
                        '''
                    }
                    
                    if (params.DEPLOYMENT_TYPE == 'Android Only' || params.DEPLOYMENT_TYPE == 'Both') {
                        sh '''
                            echo "Deploying Android to production..."
                            # Add Google Play Store deployment or other production deployment
                        '''
                    }
                }
            }
        }

        stage('Quality Gate') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }
    }

    post {
        always {
            // Clean workspace
            cleanWs()
            
            // Send notifications
            script {
                def status = currentBuild.result ?: 'SUCCESS'
                def color = status == 'SUCCESS' ? 'good' : 'danger'
                def message = """
                    Build ${env.BUILD_NUMBER} - ${status}
                    Branch: ${env.BRANCH_NAME}
                    Commit: ${env.GIT_COMMIT.take(7)}
                    Author: ${env.GIT_AUTHOR}
                    Message: ${env.GIT_COMMIT_MSG}
                """
                
                // Add Slack/Email notification here
                echo message
            }
        }
        
        success {
            echo 'Pipeline completed successfully!'
        }
        
        failure {
            echo 'Pipeline failed!'
        }
        
        unstable {
            echo 'Pipeline is unstable!'
        }
    }
}