/*global module:false*/
module.exports = function(grunt) {
	var path = require('path');
	var SOURCE_DIR = 'src/';
	var BUILD_DIR = 'build/';

	// Project configuration.
	grunt.initConfig({
		clean: {
			all: [BUILD_DIR],
			dynamic: {
				dot: true,
				expand: true,
				cwd: BUILD_DIR,
				src: []
			}
		},
		copy: {
			all: {
				dot: true,
				expand: true,
				cwd: SOURCE_DIR,
				src: ['**','!**/.{svn,git}/**'], // Ignore version control directories.
				dest: BUILD_DIR
		  },
		  dynamic: {
				dot: true,
				expand: true,
				cwd: SOURCE_DIR,
				dest: BUILD_DIR,
				src: []
			}
		},
		watch: {
			all: {
				files: [SOURCE_DIR + '**'],
				tasks: ['clean:dynamic', 'copy:dynamic'],
				options: {
					dot: true,
					nospawn: true
				}
			}
		}
	});

	// Load tasks.
	grunt.loadNpmTasks('grunt-contrib-clean');
	grunt.loadNpmTasks('grunt-contrib-copy');
	grunt.loadNpmTasks('grunt-contrib-watch');

	// Default task.
	grunt.registerTask('default', ['clean:all', 'copy:all']);

	// Add a listener to the watch task.
	//
	// On `watch:all`, automatically updates the `copy:dynamic` and `clean:dynamic`
	// configurations so that only the changed files are updated.
	grunt.event.on('watch', function(action, filepath, target) {
		if (target != 'all') return;

		var relativePath = path.relative(SOURCE_DIR, filepath);
		var cleanSrc = (action == 'deleted') ? [relativePath] : [];
		var copySrc = (action == 'deleted') ? [] : [relativePath];
		grunt.config(['clean', 'dynamic', 'src'], cleanSrc);
		grunt.config(['copy', 'dynamic', 'src'], copySrc);
	});
};
