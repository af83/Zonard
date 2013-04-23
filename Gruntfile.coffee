module.exports = (grunt)->
  
  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-coffeelint'

  grunt.initConfig
    coffeelint:
      app:
        files:
          src: ['Gruntfile.coffee', 'assets/**/*.coffee']
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

    watch:
      files: ['assets/**/*.coffee']
      tasks: ['coffeelint', 'coffee']


  grunt.registerTask 'default', ['coffeelint', 'coffee']
