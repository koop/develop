/*global module:false*/
module.exports = function(grunt) {
	// Project configuration.
	grunt.initConfig({
		clean: {
			build: ['build']
		},
		copy: {
			build: {
				files: [{
					expand: true,
					cwd: 'src/',
					src: ['**'],
					dest: 'build/'
				}]
		  }
		}
	});

	// Load tasks.
	grunt.loadNpmTasks('grunt-contrib-clean');
	grunt.loadNpmTasks('grunt-contrib-copy');

	// Default task.
	grunt.registerTask('default', ['clean', 'copy']);
};
