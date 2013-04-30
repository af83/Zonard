module.exports = (grunt)->

  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-sass'
  grunt.loadNpmTasks 'grunt-coffeelint'
  grunt.loadNpmTasks 'grunt-mocha'

  grunt.initConfig
    coffeelint:
      app:
        files:
          src: ['Gruntfile.coffee', 'assets/**/*.coffee', 'test/**/*.coffee']
        options:
          max_line_length:
            level: 'warn'
    coffee:
      glob_to_multiple:
        expand: true
        flatten: true
        cwd: 'assets/js/'
        src: ['*.coffee']
        dest: 'assets/js/'
        ext: '.js'
      test:
        expand: true
        flatten: true
        cwd: 'test/'
        src: ['*.coffee']
        dest: 'test/'
        ext: '.js'
    sass:
      dist:
        files:
          'assets/css/main.css': 'assets/css/BlockView.sass'
    mocha:
      options:
        run: true
      test:
        src: ['test/**/*.html']
    watch:
      files: ['assets/**/*.coffee', 'assets/css/**/*.sass', 'test/**/*.coffee']
      tasks: ['coffeelint', 'coffee', 'sass', 'mocha']


  grunt.registerTask 'default', ['coffeelint', 'coffee', 'sass', 'mocha']
