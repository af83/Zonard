module.exports = (grunt)->

  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-sass'
  grunt.loadNpmTasks 'grunt-contrib-jshint'
  grunt.loadNpmTasks 'grunt-coffeelint'
  grunt.loadNpmTasks 'grunt-mocha'

  grunt.initConfig
    coffeelint:
      app:
        files:
          src: ['Gruntfile.coffee', 'assets/**/*.coffee', 'test/**/*.coffee', 'lib/**/*.coffee', 'example/**/*.coffee']
        options:
          max_line_length:
            level: 'warn'
    jshint:
      manifest: ['*.json']
    coffee:
      lib:
        expand: true
        flatten: true
        cwd: 'lib/'
        src: ['*.coffee']
        dest: 'dist/js/'
        ext: '.js'
      example:
        expand: true
        flatten: true
        cwd: 'example/'
        src: ['*.coffee']
        dest: 'dist/js/'
        ext: '.js'
      test:
        expand: true
        flatten: true
        cwd: 'test/'
        src: ['*.coffee']
        dest: 'test/'
        ext: '.js'
    sass:
      assets:
        files:
          'assets/css/main.css': 'assets/css/BlockView.sass'
    mocha:
      options:
        run: true
      test:
        src: ['test/**/*.html']
    watch:
      files: ['assets/**/*.coffee', 'assets/css/**/*.sass', 'test/**/*.coffee', 'lib/**/*.coffee', 'example/**/*.coffee']
      tasks: ['coffeelint', 'coffee', 'sass', 'mocha']


  grunt.registerTask 'default', ['jshint', 'coffeelint', 'coffee', 'sass', 'mocha']
