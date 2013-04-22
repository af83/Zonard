module.exports = (grunt)->
  
  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-coffeelint'

  grunt.initConfig
    coffeelint:
      files:['Gruntfile.coffee', 'assets/**/*.coffee']
    coffee:
      files: ['assets/**/*.coffee']
    watch:
      files: ['example/**/*.coffee']
      tasks: ['coffeelint', 'coffee']


  grunt.registerTask 'default', ['coffeelint', 'coffee']
