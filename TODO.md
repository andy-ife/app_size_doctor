~~IMPORTANT!!! Show potential space savings BEFORE running clean or compression~~

1. ~~What if there is discrepancy between assets declared in pubspec.yaml and actual found files/directories.~~
2. ~~Make the main runner more class-like to reduce passing args to every function~~
3. ~~Revamp the printTree, buildTree, displayResults methods.~~
4. ~~Wrap libraries in classes for improved testability~~
5. Display results by Root assets, Android, iOS, macOS, Windows, and Linux sections
6. ~~Add getters to assetCleaner and assetCompressor. These are what assetAnalyzer, assetDoctor and others should use to access the cleaner's/compressor's properties~~
7. ~~Add error handling to app.dart~~
8. Add support for passing projectRoot and ignoredDirs in app.dart arguments
9. ~~Improve organisation/location of some files/deps~~
10. ~~Consider Move the complex work from app.dart to file_utils~~
11. ~~Add analysis cli mode~~
12. Upgrade image_compression dep. It depends on mime 1.0.0 which is causing issues in some projects
13. Define app Exceptions, throw them appropriately and handle them in the application layer (or maybe app.dart)
14. Work on video and audio compression layer
15. ~~Allow user to choose 'unused' assets to keep (not delete), and 'used' assets to NOT compress~~
16. Ensure the output file format after compression is same as input. Consider adding option for users to allow changing file format or not
17. ~~Compression client should use fs, not dart:io directly.~~
18. ~~Compressor should check for unused assets and advice deletion. It does NOT compress unused assets~~
19. Allow users to set compression level
20. ~~Add interactive picker for user to select files to NOT clean or NOT compress~~
21. Optimize Android and iOS regex searches. Apply correct regex to correct file types only
22. Don't be too quick to delete files. Consider adding used, unused, and indefinite/unclear states. Lean towards keeping unclear/indefinite files
23. Move away from interact_cli dependency. Implement our own custom list selector
