hugo
git checkout master
cp -r public/* .
rm -r public
git add .
git commit -m "Deploy new posts" 
