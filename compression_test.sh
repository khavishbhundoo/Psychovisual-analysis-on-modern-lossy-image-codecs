#!/bin/bash
#
#####################################################
#                                                   #
# Author : Khavish Anshudass Bhundoo                #
# License : MIT                                     #
# Performs compression tests using multiple encoders#
#####################################################


#Check if a command line tool is installed on the server
function exists()
{
  command -v "$1" >/dev/null 2>&1
}

function usage()
{
  echo "Usage: $(basename "${BASH_SOURCE}") [options] image1.png image2.png ..."
  echo "Main Options"
  echo "--only-pik              	Redo the test[image generation + csv ] only for pik & regenerate plots"
  echo "--only-libjpeg          	Redo the test[image generation + csv ] only for libjpeg & regenerate plots"
  echo "--only-libjpeg-2000     	Redo the test[image generation + csv ] only for libjpeg 2000 & regenerate plots"
  echo "--only-guetzli          	Redo the test[image generation + csv ] only for guezli & regenerate plots"
  echo "--only-flif-lossy       	Redo the test[image generation + csv ] only for flif(lossy) & regenerate plots"
  echo "--only-webp             	Redo the test[image generation + csv ] only for webp(near-lossless) & regenerate plots"
  echo "--only-webp-lossy       	Redo the test[image generation + csv ] only for webp(lossy) and regenerate plots"
  echo "--only-bpg-lossy        	Redo the test[image generation + csv ] only for bgp(lossy) and regenerate plots"
  echo "--only-bpg-lossy-jctvc  	Redo the test[image generation + csv ] only for bgp(lossy) and regenerate plots"
  echo "--only-mozjpeg          	Redo the test[image generation + csv ] only for mozjpeg and regenerate plots"
  echo "--only-av1              	Redo the test[image generation + csv ] only for av1 and regenerate plots"
  echo "--only-plots            	Only regenerate plots"
  echo "--only-csv              	Only regenerate csv files and plots"
  echo "--combine-plots         	Merge results of multiple images to create a single butteraugli and ssimulacra plot"
  echo "--heatmap_target_size=SIZE  Generate butteraugli heatmaps for a compressed image just above SIZE for each encoder"
  echo "--path=/path/goes/here 		Use all png images in directory as source(no trailing / )"
  exit 1

}


function check_dependancies()
{

  missing_deps=false

  if ! exists butteraugli; then
    echo 'Butteraugli is not installed...exiting'
    missing_deps=true
  fi

  if ! exists guetzli; then
    echo 'Guetzli is not installed...exiting'
    missing_deps=true
  fi

  if ! exists ssimulacra; then
    echo 'Ssimulacra is not installed...exiting'
    missing_deps=true
  fi

  if ! exists identify; then
    echo 'ImageMagick is not installed...exiting'
    missing_deps=true
  fi

  if ! exists cpik || ! exists dpik ; then
    echo 'Pik is not installed...exiting'
    missing_deps=true
  fi

  if ! exists cwebp || ! exists dwebp ; then
    echo 'Webp is not installed...exiting'
    missing_deps=true
  fi

  if ! exists aomenc || ! exists dwebp ; then
    echo 'av1 is not installed...exiting'
    missing_deps=true
  fi

  if ! exists bc; then
    echo 'bc is not installed...exiting'
    missing_deps=true
  fi

  if ! exists jpeg; then
    echo 'libjpeg is not installed...exiting'
    missing_deps=true
  fi

  if ! exists opj_compress || ! exists opj_decompress ; then
    echo 'OpenJPEG is not installed...exiting'
    missing_deps=true
  fi

  if ! exists gnuplot; then
    echo 'gnuplot is not installed...exiting'
    missing_deps=true
  fi

  if ! exists zip; then
    echo 'zip is not installed...exiting'
    missing_deps=true
  fi

  if ! exists bpgenc || ! exists bpgdec ; then
    echo 'libbpg is not installed...exiting'
    missing_deps=true
  fi

  if ! exists flif; then
    echo 'flif is not installed...exiting'
    missing_deps=true
  fi

  if ! exists cjpeg || ! exists djpeg; then
    echo 'MozJPEG is not installed...exiting'
    missing_deps=true
  fi

  if ! exists datamash; then
    echo 'datamash is not installed...exiting'
    missing_deps=true
  fi

  #TODO need to ensure we have 2017 version of gnu parallel as we use parset
  if ! exists parallel; then
    echo 'gnu parallel is not installed...exiting'
    missing_deps=true
  fi

  if [ "$missing_deps" = true ] ; then
    exit 1
  fi


}

#Convert filesize(bytes) to bits per pixels(bpp)
function convert_to_bpp
{
  local filesize=$1
  local bpp
  bpp=$(echo "(($filesize * 8) / ($width * $height))" | bc -l)
  printf -v bpp "%0.2f" "$bpp" #set to 2 dp
  echo "$bpp"
}

function plotcsv_graph
{
  gnuplot -persist <<-EOFMarker
    set terminal pngcairo size 1280,1024 enhanced font "Helvetica,20"
	set style line 1 lt 1 lw 2 lc rgb '#00707A' ps 0 # dark green
    set style line 2 lt 1 lw 2 lc rgb '#8710A8' ps 0 # purple
    set style line 3 lt 1 lw 2 lc rgb '#005ACB' ps 0 # dark blue
    set style line 4 lt 1 lw 2 lc rgb '#099BFC' ps 0 # light blue
    set style line 5 lt 1 lw 2 lc rgb '#FF75FE' ps 0 # pink
    set style line 6 lt 1 lw 2 lc rgb '#08D8DD' ps 0 # cyan
    set style line 7 lt 1 lw 2 lc rgb '#A90B3C' ps 0 # brown
    set style line 8 lt 1 lw 2 lc rgb '#F67A4E' ps 0 # orange 
	set style line 9 lt 1 lw 2 lc rgb '#09B460' ps 0 # dark green
	set style line 10 lt 1 lw 2 lc rgb '#EFEF3A' ps 0 # yellow 
    set style line 11 lt 1 lw 2 lc rgb '#A6F687' ps 0 # light green
	set style line 12 lt 1 lw 2 lc rgb '#FBE5BC' ps 0 # light brown
    set tics nomirror
	set ytics 1
	set mytics 10
    set output "$1"
	set title  "$3"
    set xlabel 'Bits per pixel(bpp)'
    set ylabel 'butteraugli score'
	set style func linespoints
	set datafile separator ","
	set xtics font ", 12"
	set xrange [:8]
	set arrow from $reference_jpg_bpp, graph 0 to $reference_jpg_bpp, graph 1 nohead lt 0
	plot "pik-$2.csv" using 3:4 w l ls 1 title 'pik', \
    "libjpeg-$2.csv" using 3:4 w l ls 2  title 'libjpeg', \
	"libjpeg2000-$2.csv" using 3:4 w l ls 3  title 'OpenJPEG(JPEG 2000)', \
    "guetzli-$2.csv" using 3:4 w l ls 4 title 'guetzli', \
    "flif_lossy-$2.csv" using 3:4 w l ls 5 title 'flif-lossy', \
	"bpg-$2.csv" using 3:4 w l ls 6 title 'bpg(x265)', \
	"bpg_jctvc-$2.csv" using 3:4 w l ls 7 title 'bpg(jctvc)', \
	"mozjpeg-$2.csv" using 3:4 w l ls 8  title 'MozJPEG', \
	"av1-$2.csv" using 4:5 w l ls 9 title 'AV1', \
	"webp-$2.csv" using 3:4 w l ls 10 title 'webp-near-lossless-40/60', \
	"webp_lossy-$2.csv" using 3:4 w l ls 12 title 'webp-lossy', \
	1/0 t "Reference Size" lt 0
EOFMarker
}

function plotcsv_graph_ssimulacra
{
  gnuplot -persist <<-EOFMarker
    set terminal pngcairo size 1280,1024 enhanced font "Helvetica,20"
	set style line 1 lt 1 lw 2 lc rgb '#00707A' ps 0 # dark green
    set style line 2 lt 1 lw 2 lc rgb '#8710A8' ps 0 # purple
    set style line 3 lt 1 lw 2 lc rgb '#005ACB' ps 0 # dark blue
    set style line 4 lt 1 lw 2 lc rgb '#099BFC' ps 0 # light blue
    set style line 5 lt 1 lw 2 lc rgb '#FF75FE' ps 0 # pink
    set style line 6 lt 1 lw 2 lc rgb '#08D8DD' ps 0 # cyan
    set style line 7 lt 1 lw 2 lc rgb '#A90B3C' ps 0 # brown
    set style line 8 lt 1 lw 2 lc rgb '#F67A4E' ps 0 # orange 
	set style line 9 lt 1 lw 2 lc rgb '#09B460' ps 0 # dark green
	set style line 10 lt 1 lw 2 lc rgb '#EFEF3A' ps 0 # yellow 
    set style line 11 lt 1 lw 2 lc rgb '#A6F687' ps 0 # light green
	set style line 12 lt 1 lw 2 lc rgb '#FBE5BC' ps 0 # light brown
    set tics nomirror
	set ytics 0.01
	set mytics 10
    set output "$1"
	set title  "$3"
    set xlabel 'Bits per pixel(bpp)'
    set ylabel 'ssimulacra score'
	set datafile separator ","
	set xtics font ", 12"
	set xrange [:8]
	set arrow from $reference_jpg_bpp, graph 0 to $reference_jpg_bpp, graph 1 nohead lt 0
	plot "pik-$2.csv" using 3:5 w l ls 1 title 'pik', \
    "libjpeg-$2.csv" using 3:5 w l ls 2 title 'libjpeg', \
	"libjpeg2000-$2.csv" using 3:5 w l ls 3 title 'OpenJPEG(JPEG 2000)', \
    "guetzli-$2.csv" using 3:5 w l ls 4 title 'guetzli', \
    "flif_lossy-$2.csv" using 3:5 w l ls 5 title 'flif-lossy', \
	"bpg-$2.csv" using 3:5 w l ls 6 title 'bpg(x265)', \
	"bpg_jctvc-$2.csv" using 3:5 w l ls 7 title 'bpg(jctvc)', \
	"mozjpeg-$2.csv" using 3:5 w l ls 8 title 'MozJPEG', \
	"av1-$2.csv" using 4:6 w l ls 9 title 'AV1', \
	"webp-$2.csv" using 3:5 w l ls 10 title 'webp-near-lossless-40/60', \
	"webp_lossy-$2.csv" using 3:5 w l ls 12 title 'webp-lossy', \
	1/0 t "Reference Size" lt 0
EOFMarker
}

function plotcsv_graph_merge
{
  gnuplot -persist <<-EOFMarker
	set terminal pngcairo size 1280,1024 enhanced font "Helvetica,20"
	set style line 1 lt 1 lw 2 lc rgb '#00707A' ps 0 # dark green
    set style line 2 lt 1 lw 2 lc rgb '#8710A8' ps 0 # purple
    set style line 3 lt 1 lw 2 lc rgb '#005ACB' ps 0 # dark blue
    set style line 4 lt 1 lw 2 lc rgb '#099BFC' ps 0 # light blue
    set style line 5 lt 1 lw 2 lc rgb '#FF75FE' ps 0 # pink
    set style line 6 lt 1 lw 2 lc rgb '#08D8DD' ps 0 # cyan
    set style line 7 lt 1 lw 2 lc rgb '#A90B3C' ps 0 # brown
    set style line 8 lt 1 lw 2 lc rgb '#F67A4E' ps 0 # orange 
	set style line 9 lt 1 lw 2 lc rgb '#09B460' ps 0 # dark green
	set style line 10 lt 1 lw 2 lc rgb '#EFEF3A' ps 0 # yellow 
    set style line 11 lt 1 lw 2 lc rgb '#A6F687' ps 0 # light green
	set style line 12 lt 1 lw 2 lc rgb '#FBE5BC' ps 0 # light brown
    set tics nomirror
	set ytics 1
	set mytics 10
    set output "$1"
	set title  "$2"
    set xlabel 'Bits per pixel(bpp)'
    set ylabel 'butteraugli score'
	set datafile separator ","
	set xtics font ", 12"
	set xrange [:8]
	plot "pik-merge.csv" using 2:3 w l ls 1  title 'pik', \
    "libjpeg-merge.csv" using 2:3 w l  ls 2 title 'libjpeg', \
	"libjpeg2000-merge.csv" using 2:3  w l ls 3 title 'OpenJPEG(JPEG 2000)', \
    "guetzli-merge.csv" using 2:3 w l ls 4 title 'guetzli', \
    "flif_lossy-merge.csv" using 2:3 w l ls 5 title 'flif-lossy', \
	"bpg-merge.csv" using 2:3 w l ls 6 title 'bpg(x265)', \
	"bpg_jctvc-merge.csv" using 2:3 w l ls 7 title 'bpg(jctvc)', \
	"mozjpeg-merge.csv" using 2:3 w l ls 8 title 'MozJPEG', \
	"av1-merge.csv" using 3:4 w l ls 9 title 'AV1', \
	"webp-merge.csv" using 2:3  w l ls 10 title 'webp-near-lossless-40/60', \
	"webp_lossy-merge.csv" using 2:3 w l ls 12 title 'webp-lossy'
EOFMarker
}

function plotcsv_graph_ssimulacra_merge
{
  gnuplot -persist <<-EOFMarker
    set terminal pngcairo size 1280,1024 enhanced font "Helvetica,20"
	set style line 1 lt 1 lw 2 lc rgb '#00707A' ps 0 # dark green
    set style line 2 lt 1 lw 2 lc rgb '#8710A8' ps 0 # purple
    set style line 3 lt 1 lw 2 lc rgb '#005ACB' ps 0 # dark blue
    set style line 4 lt 1 lw 2 lc rgb '#099BFC' ps 0 # light blue
    set style line 5 lt 1 lw 2 lc rgb '#FF75FE' ps 0 # pink
    set style line 6 lt 1 lw 2 lc rgb '#08D8DD' ps 0 # cyan
    set style line 7 lt 1 lw 2 lc rgb '#A90B3C' ps 0 # brown
    set style line 8 lt 1 lw 2 lc rgb '#F67A4E' ps 0 # orange 
	set style line 9 lt 1 lw 2 lc rgb '#09B460' ps 0 # dark green
	set style line 10 lt 1 lw 2 lc rgb '#EFEF3A' ps 0 # yellow 
    set style line 11 lt 1 lw 2 lc rgb '#A6F687' ps 0 # light green
	set style line 12 lt 1 lw 2 lc rgb '#FBE5BC' ps 0 # light brown
    set tics nomirror
	set ytics 0.01
	set mytics 10
    set output "$1"
	set title  "$2"
    set xlabel 'Bits per pixel(bpp)'
    set ylabel 'ssimulacra score'
	set datafile separator ","
	set xtics font ", 12"
	set xrange [:8]
	plot "pik-merge.csv" using 2:4 w l ls 1 title 'pik', \
    "libjpeg-merge.csv" using 2:4 w l ls 2 title 'libjpeg', \
	"libjpeg2000-merge.csv" using 2:4 w l ls 3 title 'OpenJPEG(JPEG 2000)', \
    "guetzli-merge.csv" using 2:4 w l ls 4 title 'guetzli', \
    "flif_lossy-merge.csv" using 2:4 w l ls 5 title 'flif-lossy', \
	"bpg-merge.csv" using 2:4 w l ls 6 title 'bpg(x265)', \
	"bpg_jctvc-merge.csv" using 2:4 w l ls 7 title 'bpg(jctvc)', \
	"mozjpeg-merge.csv" using 2:4 w l ls 8 title 'MozJPEG', \
	"av1-merge.csv" using 3:5 w l ls 9 title 'AV1', \
	"webp-merge.csv" using 2:4 w l ls 10 title 'webp-near-lossless-40/60', \
	"webp_lossy-merge.csv" using 2:4 w l ls 12 title 'webp-lossy'
EOFMarker
}


#TODO : Add paralleism for computing psycovisual scores
function libjpeg_test
{
  echo "Analysing JPEGs optimized by LibJPEG[Source :$x]"
  rm -rf libjpeg-"$filename".csv
  #Start csv generation
  echo "Test_Image,Original_Size(bytes),Original_Size(bpp)" >> libjpeg-"$filename".csv
  echo "$filename","$orig_size","$orig_size_bpp" >> libjpeg-"$filename".csv
  echo "Quality,Size(bytes),Size(bpp),Butteraugli,Ssimulacra,Compression Rate(%),Reference Compression Rate(%)" >> libjpeg-"$filename".csv
  if [ "$only_csv" = false ]; then
    echo "Generating JPEGs optimized by LibJPEG[Source :$x] in parallel"
    #ImageMagick uses an old version of libjpeg so i take the latest one from github for accuracy
    #parallel --will-cite 'convert "{1}" -quality "{2}" -sampling-factor 1x1 "{3}"_libjpeg_q"{2}".jpg' ::: "$x" ::: {100..70} ::: "$filename"
    parallel --will-cite 'jpeg -q "{1}" -oz  -qt 3 -qv -h "{2}".ppm "{3}"_libjpeg_q"{1}".jpg' ::: {100..70} ::: "$x" ::: "$filename"
  fi
  echo "Perform comparisions and store results in libjpeg-$filename.csv"
  for ((i=100; i>=70; i--))
  do
    #ImageMagick uses an old version of libjpeg so i take the latest one from github for accuracy
    #convert "$x" -quality "$i" -sampling-factor 1x1 "$filename"_libjpeg_q"$i".jpg
    #jpeg -q "$i" -oz -v -qt 3 -h  "$x".ppm "$filename"_libjpeg_q"$i".jpg
    new_size=$(wc -c < "$filename"_libjpeg_q"$i".jpg)
    new_size_bpp=$(convert_to_bpp "$new_size")
    butteraugli_score=$(butteraugli "$x" "$filename"_libjpeg_q"$i".jpg)
    ssimulacra_score=$(ssimulacra "$x" "$filename"_libjpeg_q"$i".jpg)
    compression_rate=$(echo "(($orig_size - $new_size) / $orig_size) * 100" | bc -l)
    reference_compression_rate=$(echo "(($reference_jpg_size - $new_size) / $reference_jpg_size) * 100" | bc -l)
    printf -v compression_rate "%0.2f" "$compression_rate" #set to 2 dp
    printf -v reference_compression_rate "%0.2f" "$reference_compression_rate" #set to 2 dp
    echo "$i","$new_size","$new_size_bpp","$butteraugli_score","$ssimulacra_score","$compression_rate","$reference_compression_rate" >> libjpeg-"$filename".csv
  done
#End csv generation
}

function av1_test
{
  echo "Analysing images optimized by AV1"
  rm -rf av1-"$filename".csv "$x".y4m
  ffmpeg -nostats -loglevel 0 -y -i  "$x" -pix_fmt yuv444p10le -strict -2 "$x".y4m
  #Start csv generation
  echo "Test_Image,Original_Size(bytes),Original_Size(bpp)" >> av1-"$filename".csv
  echo "$filename","$orig_size","$orig_size_bpp" >> av1-"$filename".csv
  echo "Quality(cq-level),Flatness(qm-min),Size(bytes),Size(bpp),Butteraugli,Ssimulacra,Compression Rate(%),Reference Compression Rate(%)" >> av1-"$filename".csv
  #Do image generation in parallel
  if [ "$only_csv" = false ]; then
  cmd_arr=()
  for q in 10 12 14 16 18 20 22 24 26 28 30 32 34 36 38 40; do
    for i in 4 6 8 10 12; do
		cmd_arr+=("aomenc $x.y4m --i444 --enable-qm=1 --qm-min=$i --profile=3 -w $width -h $height -b 10 --end-usage=q --cq-level=$q -o ${x}_${q}_${i}.ivf")
	done
  done
  for q in 10 12 14 16 18 20 22 24 26 28 30 32 34 36 38 40; do
    for i in 4 6 8 10 12; do
		cmd_arr+=("aomdec ${x}_${q}_${i}.ivf --output-bit-depth=10 -o ${x}_${q}_${i}.y4m")
	done
  done
  for q in 10 12 14 16 18 20 22 24 26 28 30 32 34 36 38 40; do
    for i in 4 6 8 10 12; do
		cmd_arr+=("ffmpeg -nostats -loglevel 0 -y -i ${x}_${q}_${i}.y4m ${x}_${q}_${i}.png")
	done
  done
  for q in 10 12 14 16 18 20 22 24 26 28 30 32 34 36 38 40; do
    for i in 4 6 8 10 12; do
		cmd_arr+=("convert ${x}_${q}_${i}.png PNG24:${x}_${q}_${i}_ssimulacra.png")
	done
  done
  #keep order to ensure we are able to generate png successfully
  parallel --will-cite -k  ::: "${cmd_arr[@]}"
  unset cmd_arr
  fi
  
  for q in 10 12 14 16 18 20 22 24 26 28 30 32 34 36 38 40; do
    for i in 4 6 8 10 12; do
      #if [ "$only_csv" = false ]; then		
        # aomenc "$x".y4m --i444 --enable-qm=1 --qm-min="$i" --profile=3 -w "$width" -h "$height" -b 10 --end-usage=q --cq-level="$q" -o "$x"_"$q"_"$i".ivf
        # aomdec "$x"_"$q"_"$i".ivf --output-bit-depth=10 -o "$x"_"$q"_"$i".y4m
        # ffmpeg -nostats -loglevel 0 -y -i "$x"_"$q"_"$i".y4m "$x"_"$q"_"$i".png
        # convert "$x"_"$q"_"$i".png PNG24:"$x"_"$q"_"$i"_ssimulacra.png # ssimulacra can't handle generated png
      #fi
      new_size=$(wc -c < "$x"_"$q"_"$i".ivf)
      new_size_bpp=$(convert_to_bpp "$new_size")
      butteraugli_score=$(butteraugli "$x" "$x"_"$q"_"$i".png)
      ssimulacra_score=$(ssimulacra "$x" "$x"_"$q"_"$i"_ssimulacra.png)
      compression_rate=$(echo "(($orig_size - $new_size) / $orig_size) * 100" | bc -l)
      reference_compression_rate=$(echo "(($reference_jpg_size - $new_size) / $reference_jpg_size) * 100" | bc -l)
      printf -v compression_rate "%0.2f" "$compression_rate" #set to 2 dp
      printf -v reference_compression_rate "%0.2f" "$reference_compression_rate" #set to 2 dp
      echo "$q","$i","$new_size","$new_size_bpp","$butteraugli_score","$ssimulacra_score","$compression_rate","$reference_compression_rate" >> av1-"$filename".csv
    done
  done
#End csv generation
}

function libjpeg_2000_test
{
  echo "Analysing JPEG 2000 images optimized by OpenJPEG(JPEG 2000)[Source :$x]"
  rm -rf libjpeg2000-"$filename".csv
  #Start csv generation
  echo "Test_Image,Original_Size,Original_Size(bpp)" >> libjpeg2000-"$filename".csv
  echo "$filename","$orig_size","$orig_size_bpp" >> libjpeg2000-"$filename".csv
  echo "Quality,Size(bytes),Size(bpp),Butteraugli,Ssimulacra,Compression Rate(%),Reference Compression Rate(%)" >> libjpeg2000-"$filename".csv
  if [ "$only_csv" = false ]; then
    echo "Generating JPEG 2000 images optimized by LibJPEG[Source :$x] in parallel"
    parallel --will-cite 'opj_compress -i "{1}".ppm -r "{2}" -o "{3}"_openjpeg_q"{2}".jp2 -I -r "{2}"' ::: "$x" ::: {0..25}  ::: "$filename"
    parallel --will-cite 'opj_decompress -i "{3}"_openjpeg_q"{2}".jp2  -o "{3}"_openjpeg_q"{2}".png' ::: "$x" ::: {0..25}  ::: "$filename"
  fi
  echo "Perform comparisions and store results in libjpeg2000-$filename.csv"
  for ((i=0; i<=25; i++))
  do
    #opj_compress -i "$x".ppm -r "$i" -o "$filename"_openjpeg_q"$i".jp2 -I -r "$i"
    #opj_decompress -i "$filename"_openjpeg_q"$i".jp2  -o "$filename"_openjpeg_q"$i".png
    new_size=$(wc -c < "$filename"_openjpeg_q"$i".jp2)
    new_size_bpp=$(convert_to_bpp "$new_size")
    butteraugli_score=$(butteraugli "$x" "$filename"_openjpeg_q"$i".png)
    ssimulacra_score=$(ssimulacra "$x" "$filename"_openjpeg_q"$i".png)
    compression_rate=$(echo "(($orig_size - $new_size) / $orig_size) * 100" | bc -l)
    reference_compression_rate=$(echo "(($reference_jpg_size - $new_size) / $reference_jpg_size) * 100" | bc -l)
    printf -v compression_rate "%0.2f" "$compression_rate" #set to 2 dp
    printf -v reference_compression_rate "%0.2f" "$reference_compression_rate" #set to 2 dp
    echo "$i","$new_size","$new_size_bpp","$butteraugli_score","$ssimulacra_score","$compression_rate","$reference_compression_rate" >> libjpeg2000-"$filename".csv
  done
#End csv generation
}

function guetzli_test
{
  echo "Analysing JPEGs optimized by Guetzli[Source :$x]"
  rm -rf guetzli-"$filename".csv
#Start csv generation
  echo "Test_Image,Original_Size,Original_Size(bpp)" >> guetzli-"$filename".csv
  echo "$filename","$orig_size","$orig_size_bpp" >> guetzli-"$filename".csv
  echo "Quality,Size(bytes),Size(bpp),Butteraugli,Ssimulacra,Compression Rate(%),Reference Compression Rate(%)" >> guetzli-"$filename".csv
  if [ "$only_csv" = false ]; then
    echo "Generating JPEGs optimized by Guetzli(This will take a while...BE patient)[Source :$x] in parallel"
    parallel --will-cite 'guetzli --nomemlimit --quality "{2}"  "{1}"  "{3}"_guetzli_q"{2}".jpg' ::: "$x" ::: {100..84} ::: "$filename"
  fi
  echo "Perform comparisions and store results in guetzli-$filename.csv"
  for ((i=100; i>=84; i--))
  do
    #guetzli --quality "$i"  "$x"  "$filename"_guetzli_q"$i".jpg
    new_size=$(wc -c < "$filename"_guetzli_q"$i".jpg)
    new_size_bpp=$(convert_to_bpp "$new_size")
    butteraugli_score=$(butteraugli "$x" "$filename"_guetzli_q"$i".jpg)
    ssimulacra_score=$(ssimulacra "$x" "$filename"_guetzli_q"$i".jpg)
    compression_rate=$(echo "(($orig_size - $new_size) / $orig_size) * 100" | bc -l)
    reference_compression_rate=$(echo "(($reference_jpg_size - $new_size) / $reference_jpg_size) * 100" | bc -l)
    printf -v compression_rate "%0.2f" "$compression_rate" #set to 2 dp
    printf -v reference_compression_rate "%0.2f" "$reference_compression_rate" #set to 2 dp
    echo "$i","$new_size","$new_size_bpp","$butteraugli_score","$ssimulacra_score","$compression_rate","$reference_compression_rate" >> guetzli-"$filename".csv
  done
#End csv generation
}

function mozjpeg_test
{
  rm -rf mozjpeg-"$filename".csv
  orig_size_bpp=$(convert_to_bpp "$orig_size")
  echo "Analysing JPEGs optimized by MozJPEG[Source :$x]"
  #Start csv generation
  echo "Test_Image,Original_Size,Original_Size(bpp)" >> mozjpeg-"$filename".csv
  echo "$filename","$orig_size","$orig_size_bpp" >> mozjpeg-"$filename".csv
  echo "Quality,Size(bytes),Size(bpp),Butteraugli,Ssimulacra,Compression Rate(%),Reference Compression Rate(%)" >> mozjpeg-"$filename".csv
  if [ "$only_csv" = false ]; then
    echo "Generating JPEGs optimized by MozJPEG[Source :$x] in parallel"
    parallel --will-cite 'cjpeg -sample 1x1 -quality "{1}" -outfile "{2}"_mozjpeg_q{1}.jpg {3}' ::: {100..70}  ::: "$filename" ::: "$x"
  fi
  echo "Perform comparisions and store results in mozjpeg-$filename.csv"
  for ((i=100; i>=70; i--))
  do
    #cjpeg -optimize -sample 1x1 -quality "$i" -outfile "$filename"_mozjpeg_q"$i".jpg "$x"
    new_size=$(wc -c < "$filename"_mozjpeg_q"$i".jpg)
    new_size_bpp=$(convert_to_bpp "$new_size")
    butteraugli_score=$(butteraugli "$x" "$filename"_mozjpeg_q"$i".jpg)
    ssimulacra_score=$(ssimulacra "$x" "$filename"_mozjpeg_q"$i".jpg)
    compression_rate=$(echo "(($orig_size - $new_size) / $orig_size) * 100" | bc -l)
    reference_compression_rate=$(echo "(($reference_jpg_size - $new_size) / $reference_jpg_size) * 100" | bc -l)
    printf -v compression_rate "%0.2f" "$compression_rate" #set to 2 dp
    printf -v reference_compression_rate "%0.2f" "$reference_compression_rate" #set to 2 dp
    echo "$i","$new_size","$new_size_bpp","$butteraugli_score","$ssimulacra_score","$compression_rate","$reference_compression_rate" >> mozjpeg-"$filename".csv
  done
#End csv generation
}

function pik_test
{
  echo "Analysing Pik images(This will take a while...BE patient)[Source :$x]"
  rm -rf pik-"$filename".csv
  orig_size_bpp=$(convert_to_bpp "$orig_size")
#Start csv generation
  echo "Test_Image,Original_Size,Original_Size(bpp)" >> pik-"$filename".csv
  echo "$filename","$orig_size","$orig_size_bpp" >> pik-"$filename".csv
  echo "Quality,Size(bytes),Size(bpp),Butteraugli,Ssimulacra,Compression Rate(%),Reference Compression Rate(%)" >> pik-"$filename".csv
  if [ "$only_csv" = false ]; then
    echo "Generating Pik images(This will take a while...BE patient)[Source :$x] in parallel"
    parallel --will-cite 'cpik "{1}" "{3}"_q"{2}".pik --distance "{2}"' ::: "$x" ::: $(seq 0.5 0.1 3.0) ::: "$filename"
    parallel --will-cite 'dpik "{1}"_q"{2}".pik  "{1}"_pik_q"{2}".png ' ::: "$filename" ::: $(seq 0.5 0.1 3.0)
  fi
  echo "Perform comparisions and store results in pik-$filename.csv"
  for i in $(seq 0.5 0.1 3.0)
  do
    #cpik  "$x" "$filename"_q"$i".pik --distance "$i"
    new_size=$(wc -c < "$filename"_q"$i".pik)
    new_size_bpp=$(convert_to_bpp "$new_size")
    #convert to png to allow comparision
    #dpik "$filename"_q"$i".pik "$filename"_pik_q"$i".png
    butteraugli_score=$(butteraugli "$x" "$filename"_pik_q"$i".png)
    ssimulacra_score=$(ssimulacra "$x" "$filename"_pik_q"$i".png)
    compression_rate=$(echo "(($orig_size - $new_size) / $orig_size) * 100" | bc -l)
    reference_compression_rate=$(echo "(($reference_jpg_size - $new_size) / $reference_jpg_size) * 100" | bc -l)
    printf -v compression_rate "%0.2f" "$compression_rate" #set to 2 dp
    printf -v reference_compression_rate "%0.2f" "$reference_compression_rate" #set to 2 dp
    echo "$i","$new_size","$new_size_bpp","$butteraugli_score","$ssimulacra_score","$compression_rate","$reference_compression_rate" >> pik-"$filename".csv
  done
#End csv generation
}

function webp_near_lossless
{
  echo "Analysing Webp images(Near Lossless)[Source :$x]"
  rm -rf webp-"$filename".csv
#Start csv generation
  echo "Test_Image,Original_Size,Original_Size(bpp)" >> webp-"$filename".csv
  echo "$filename","$orig_size","$orig_size_bpp" >> webp-"$filename".csv
  echo "Quality,Size(bytes),Size(bpp),Butteraugli,Ssimulacra,Compression Rate(%),Reference Compression Rate(%)" >> webp-"$filename".csv
  if [ "$only_csv" = false ]; then
    echo "Generating Webp images(Near Lossless)[Source :$x] in parallel"
    parallel --will-cite 'cwebp -sharp_yuv -mt -quiet -near_lossless "{1}" -q 100 -m 6 "{2}"  -o "{3}"_webp_q{1}.webp' ::: 60 40 ::: "$x" ::: "$filename"
    parallel --will-cite 'dwebp -quiet "{1}"_webp_q"{2}".webp -o "{1}"_webp_q"{2}".png' ::: "$filename" ::: 60 40
  fi
  echo "Perform comparisions and store results in webp-$filename.csv"
  for ((i=40; i<=60; i += 20))
  do
    #The -near_lossless is the quality parameter for near_lossless , levels - 0 , 20 , 40 , 60 , 80 , 100.
    #only 40 and 60 are sensible
    #cwebp -sharp_yuv -mt -quiet -near_lossless "$i" -q 100 -m 6 "$x"  -o "$filename"_webp_q"$i".webp
    #convert to png to allow comparision
    #dwebp -quiet "$filename"_webp_q"$i".webp -o "$filename"_webp_q"$i".png
    new_size=$(wc -c < "$filename"_webp_q"$i".webp)
    new_size_bpp=$(convert_to_bpp "$new_size")
    butteraugli_score=$(butteraugli "$x" "$filename"_webp_q"$i".png)
    ssimulacra_score=$(ssimulacra "$x" "$filename"_webp_q"$i".png)
    compression_rate=$(echo "(($orig_size - $new_size) / $orig_size) * 100" | bc -l)
    reference_compression_rate=$(echo "(($reference_jpg_size - $new_size) / $reference_jpg_size) * 100" | bc -l)
    printf -v compression_rate "%0.2f" "$compression_rate" #set to 2 dp
    printf -v reference_compression_rate "%0.2f" "$reference_compression_rate" #set to 2 dp
    echo "$i","$new_size","$new_size_bpp","$butteraugli_score","$ssimulacra_score","$compression_rate","$reference_compression_rate" >> webp-"$filename".csv
  done
#End csv generation
}

function webp_lossy
{
  echo "Analysing Webp images(Lossy)[Source :$x]"
  rm -rf webp_lossy-"$filename".csv
#Start csv generation
  echo "Test_Image,Original_Size,Original_Size(bpp)" >> webp_lossy-"$filename".csv
  echo "$filename","$orig_size","$orig_size_bpp" >> webp_lossy-"$filename".csv
  echo "Quality,Size(bytes),Size(bpp),Butteraugli,Ssimulacra,Compression Rate(%),Reference Compression Rate(%)" >> webp_lossy-"$filename".csv
  if [ "$only_csv" = false ]; then
    echo "Generating Webp images(Lossy)[Source :$x] in parallel"
    parallel  --will-cite 'cwebp -sharp_yuv   -mt -quiet -q "{1}" -m 6 "{2}"  -o "{3}"_webp_lossy_q"{1}".webp' ::: {100..70}  ::: "$x" ::: "$filename"
    parallel  --will-cite 'dwebp -mt -quiet "{1}"_webp_lossy_q{2}.webp -o "{1}"_webp_lossy_q{2}.png' ::: "$filename" ::: {100..70}
  fi
  echo "Perform comparisions and store results in webp_lossy-$filename.csv"
  for ((i=100; i>=70; i--))
  do
    #cwebp -sharp_yuv -pass 10 -mt -quiet -q "$i" -m 6 "$x"  -o "$filename"_webp_lossy_q"$i".webp
    #convert to png to allow comparision
    #dwebp -quiet "$filename"_webp_lossy_q"$i".webp -o "$filename"_webp_lossy_q"$i".png
    new_size=$(wc -c < "$filename"_webp_lossy_q"$i".webp)
    new_size_bpp=$(convert_to_bpp "$new_size")
    butteraugli_score=$(butteraugli "$x" "$filename"_webp_lossy_q"$i".png)
    ssimulacra_score=$(ssimulacra "$x" "$filename"_webp_lossy_q"$i".png)
    compression_rate=$(echo "(($orig_size - $new_size) / $orig_size) * 100" | bc -l)
    reference_compression_rate=$(echo "(($reference_jpg_size - $new_size) / $reference_jpg_size) * 100" | bc -l)
    printf -v compression_rate "%0.2f" "$compression_rate" #set to 2 dp
    printf -v reference_compression_rate "%0.2f" "$reference_compression_rate" #set to 2 dp
    echo "$i","$new_size","$new_size_bpp","$butteraugli_score","$ssimulacra_score","$compression_rate","$reference_compression_rate" >> webp_lossy-"$filename".csv
  done
#End csv generation
}

function bpg_lossy
{
  echo "Analysing BPG images(x265 encoder - lossy)[Source :$x]"
  rm -rf bpg-"$filename".csv
  #Start csv generation
  echo "Test_Image,Original_Size,Original_Size(bpp)" >> bpg-"$filename".csv
  echo "$filename","$orig_size","$orig_size_bpp" >> bpg-"$filename".csv
  echo "Quality,Size(bytes),Size(bpp),Butteraugli,Ssimulacra,Compression Rate(%),Reference Compression Rate(%)" >> bpg-"$filename".csv
  if [ "$only_csv" = false ]; then
    echo "Generating BPG images(x265 encoder - lossy)[Source :$x] in parallel"
    parallel --will-cite 'bpgenc -q "{1}" -f 444  -m 9 "{2}" -o "{3}"_bpg_q{1}.bpg' ::: {0..37}  ::: "$x" ::: "$filename"
    parallel --will-cite 'bpgdec "{1}"_bpg_q"{2}".bpg -o "{1}"_bpg_q{2}.png' ::: "$filename" ::: {0..37}
  fi
  echo "Perform comparisions and store results in bpg-$filename.csv"
  for ((i=0; i<=37; i++))
  do
    #bpgenc -q "$i" -f 444  -m 9 "$x" -o "$filename"_bpg_q"$i".bpg
    #convert to png to allow comparision
    #bpgdec "$filename"_bpg_q"$i".bpg -o "$filename"_bpg_q"$i".png
    new_size=$(wc -c < "$filename"_bpg_q"$i".bpg)
    new_size_bpp=$(convert_to_bpp "$new_size")
    butteraugli_score=$(butteraugli "$x" "$filename"_bpg_q"$i".png)
    ssimulacra_score=$(ssimulacra "$x" "$filename"_bpg_q"$i".png)
    compression_rate=$(echo "(($orig_size - $new_size) / $orig_size) * 100" | bc -l)
    reference_compression_rate=$(echo "(($reference_jpg_size - $new_size) / $reference_jpg_size) * 100" | bc -l)
    printf -v compression_rate "%0.2f" "$compression_rate" #set to 2 dp
    printf -v reference_compression_rate "%0.2f" "$reference_compression_rate" #set to 2 dp
    echo "$i","$new_size","$new_size_bpp","$butteraugli_score","$ssimulacra_score","$compression_rate","$reference_compression_rate" >> bpg-"$filename".csv
  done
#End csv generation
}

function bpg_lossy_jctvc
{
  echo "Analysing BPG images(jctvc encoder - lossy)[Source :$x]"
  rm -rf bpg_jctvc-"$filename".csv
  #Start csv generation
  echo "Test_Image,Original_Size,Original_Size(bpp)" >> bpg_jctvc-"$filename".csv
  echo "$filename","$orig_size","$orig_size_bpp" >> bpg_jctvc-"$filename".csv
  echo "Quality,Size(bytes),Size(bpp),Butteraugli,Ssimulacra,Compression Rate(%),Reference Compression Rate(%)" >> bpg_jctvc-"$filename".csv
  if [ "$only_csv" = false ]; then
    echo "Generating BPG images(jctvc encoder - lossy)[Source :$x] in parallel"
    parallel --will-cite 'bpgenc -q "{1}" -f 444  -m 9 -e jctvc "{2}" -o "{3}"_bpg_jctvc_q{1}.bpg' ::: {0..37}  ::: "$x" ::: "$filename"
    parallel --will-cite 'bpgdec "{1}"_bpg_jctvc_q"{2}".bpg -o "{1}"_bpg_jctvc_q{2}.png' ::: "$filename" ::: {0..37}
  fi
  echo "Perform comparisions and store results in bpg_jctvc-$filename.csv"
  for ((i=0; i<=37; i++))
  do
    #bpgenc -q "$i" -f 444  -m 9 -e jctvc "$x" -o "$filename"_bpg_jctvc_q"$i".bpg
    #convert to png to allow comparision
    #bpgdec "$filename"_bpg_jctvc_q"$i".bpg -o "$filename"_bpg_jctvc_q"$i".png
    new_size=$(wc -c < "$filename"_bpg_jctvc_q"$i".bpg)
    new_size_bpp=$(convert_to_bpp "$new_size")
    butteraugli_score=$(butteraugli "$x" "$filename"_bpg_jctvc_q"$i".png)
    ssimulacra_score=$(ssimulacra "$x" "$filename"_bpg_jctvc_q"$i".png)
    compression_rate=$(echo "(($orig_size - $new_size) / $orig_size) * 100" | bc -l)
    reference_compression_rate=$(echo "(($reference_jpg_size - $new_size) / $reference_jpg_size) * 100" | bc -l)
    printf -v compression_rate "%0.2f" "$compression_rate" #set to 2 dp
    printf -v reference_compression_rate "%0.2f" "$reference_compression_rate" #set to 2 dp
    echo "$i","$new_size","$new_size_bpp","$butteraugli_score","$ssimulacra_score","$compression_rate","$reference_compression_rate" >> bpg_jctvc-"$filename".csv
  done
#End csv generation
}

function flif_lossy
{
  echo "Analysing FLIF images(Lossy)[Source :$x]"
  rm -rf flif_lossy-"$filename".csv
  #Start csv generation
  echo "Test_Image,Original_Size,Original_Size(bpp)" >> flif_lossy-"$filename".csv
  echo "$filename","$orig_size","$orig_size_bpp" >> flif_lossy-"$filename".csv
  echo "Quality,Size(bytes),Size(bpp),Butteraugli,Ssimulacra,Compression Rate(%),Reference Compression Rate(%)" >> flif_lossy-"$filename".csv
  if [ "$only_csv" = false ]; then
    echo "Generating FLIF images(Lossy)[Source :$x] in parallel"
    parallel --will-cite 'flif -e -E100 -o -Q"{1}"  "{2}" "{3}"_lossy_q"{1}".flif' ::: {100..0}  ::: "$x" ::: "$filename"
    parallel --will-cite 'flif -d "{1}"_lossy_q"{2}".flif "{1}"_flif_lossy_q{2}.png' ::: "$filename" ::: {100..0}
  fi
  echo "Perform comparisions and store results in flif_lossy-$filename.csv"
  for ((i=100; i>=0; i--))
  do
    #flif -e -E100 -o -Q"$i"  "$x" "$filename"_lossy_q"$i".flif
    #convert to png to allow comparision
    #flif -d "$filename"_lossy_q"$i".flif "$filename"_flif_lossy_q"$i".png
    new_size=$(wc -c < "$filename"_lossy_q"$i".flif)
    new_size_bpp=$(convert_to_bpp "$new_size")
    butteraugli_score=$(butteraugli "$x" "$filename"_flif_lossy_q"$i".png)
    ssimulacra_score=$(ssimulacra "$x" "$filename"_flif_lossy_q"$i".png)
    compression_rate=$(echo "(($orig_size - $new_size) / $orig_size) * 100" | bc -l)
    reference_compression_rate=$(echo "(($reference_jpg_size - $new_size) / $reference_jpg_size) * 100" | bc -l)
    printf -v compression_rate "%0.2f" "$compression_rate" #set to 2 dp
    printf -v reference_compression_rate "%0.2f" "$reference_compression_rate" #set to 2 dp
    echo "$i","$new_size","$new_size_bpp","$butteraugli_score","$ssimulacra_score","$compression_rate","$reference_compression_rate" >> flif_lossy-"$filename".csv
  done
#End csv generation
}



function main
{

  check_dependancies

  if [ "$#" -le 0 ]; then
    usage
  else
    for x in "$@"; do
      if [ "${x: 0:2}" != "--" ] && [ "${x: -4}" != ".png" ]; then
        echo "Only PNG images are supported"
        exit 1
      fi

      if [ "${x: 0:2}" != "--" ] && [ "${x: -4}" == ".png" ] &&  ! identify "$x" &> /dev/null; then
        echo  "$x doesn't seem to be a valid PNG...existing"
        exit 1
      fi
    done
  fi



#check which  flags are used
  has_options=false
  only_pik=false
  only_av1=false
  only_libjpeg=false
  only_libjpeg_2000=false
  only_guetzli=false
  only_webp=false
  only_webp_lossy=false
  only_bpg_lossy=false
  only_bpg_lossy_jctvc=false
  only_mozjpeg=false
  only_flif_lossy=false
  only_plots=false
  only_csv=false
  combine_plots=false
  target_size=0
  for x in "$@"; do
    if [ "${x: 0:2}" == "--" ]; then
      has_options=true
      break
    fi
  done

  if [ "$has_options" = true ]; then

    for x in "$@"; do

      #skip if not an option
      if [ "${x: 0:2}" != "--" ]; then
        continue
      fi


      if [ "$x" == "--only-libjpeg" ]; then
        only_libjpeg=true
        continue
      fi

      if [ "$x" == "--only-libjpeg-2000" ]; then
        only_libjpeg_2000=true
        continue
      fi

      if [ "$x" == "--only-guetzli" ]; then
        only_guetzli=true
        continue
      fi

      if [ "$x" == "--only-pik" ]; then
        only_pik=true
        continue
      fi

      if [ "$x" == "--only-av1" ]; then
        only_av1=true
        continue
      fi

      if [ "$x" == "--only-webp" ]; then
        only_webp=true
        continue
      fi

      if [ "$x" == "--only-flif-lossy" ]; then
        only_flif_lossy=true
        continue
      fi

      if [ "$x" == "--only-webp-lossy" ]; then
        only_webp_lossy=true
        continue
      fi

      if [ "$x" == "--only-bpg-lossy-jctvc" ]; then
        only_bpg_lossy_jctvc=true
        continue
      fi


      if [ "$x" == "--only-mozjpeg" ]; then
        only_mozjpeg=true
        continue
      fi


      if [ "$x" == "--only-plots" ]; then
        only_plots=true
        continue
      fi

      if [ "$x" == "--only-csv" ]; then
        only_csv=true
        continue
      fi


      if [ "$x" == "--combine-plots" ]; then
        combine_plots=true
        continue
      fi

      if [[ "$x" =~ ^--heatmap_target_size=.* ]] ; then
        #set target_size
        target_size=${x//[!0-9]/}
        continue
      fi
	  
	  if [[ "$x" =~ ^--path=.* ]] ; then
	    #TODO need to test
		images=()
        directory_path=${x#--path=}/*.png
		for f in $directory_path; do
			 images+=("$f")
		done
		set -- "$@" "${images[@]}"
		unset images
        continue
      fi
    done

    if [ "$target_size" -gt 0 ]; then
      #delete comparison csv
      for x in "$@"; do
        if [ "${x: 0:2}" == "--" ]; then
          continue
        fi
        filename=$(basename "$x")
        rm -rf  comparision-"$filename".csv
      done

    fi

  fi

  image_count=0
  files_to_zip=()
  list_pik=()
  list_libjpeg=()
  list_libjpeg2000=()
  list_guetzli=()
  list_flif_lossy=()
  list_bpg=()
  list_bpg_jctvc=()
  list_mozjpeg=()
  list_av1=()
  list_webp=()
  list_webp_lossy=()
  for x in "$@"; do
    #skip if we are not dealing with an image
    if [ "${x: 0:2}" == "--" ]; then
      continue
    fi
    image_count=$(( image_count + 1 ))
    filename=$(basename "$x")
    orig_size=$(wc -c < "$x")
    #convert "$x" -quality 93 -sampling-factor 1x1  "$filename"_libjpeg_reference.jpg
    convert "$x" "$x".ppm # libjpeg will require ppm file as input
    jpeg -q 93 -oz -v -qt 3 -h  "$x".ppm "$filename"_libjpeg_reference.jpg &> /dev/null
    reference_jpg_size=$(wc -c < "$filename"_libjpeg_reference.jpg)
    width=$(identify -format "%w" "$x")
    height=$(identify -format "%h" "$x")
	orig_size_bpp=$(convert_to_bpp "$orig_size")
    reference_jpg_bpp=$(convert_to_bpp "$reference_jpg_size")

    if [ "$only_libjpeg" = true ] || [ "$only_csv" = true ] || [ "$has_options" = false ]; then
      libjpeg_test
    fi

    if [ "$only_libjpeg_2000" = true ] || [ "$only_csv" = true ] || [ "$has_options" = false ]; then
      libjpeg_2000_test
    fi

    if [ "$only_mozjpeg" = true ] || [ "$only_csv" = true ] || [ "$has_options" = false ]; then
      mozjpeg_test
    fi

    if [ "$only_guetzli" = true ] || [ "$only_csv" = true ] || [ "$has_options" = false ]; then
      guetzli_test
    fi

    if [ "$only_pik" = true ] || [ "$only_csv" = true ]  || [ "$has_options" = false ]; then
      pik_test
    fi

    if [ "$only_av1" = true ] || [ "$only_csv" = true ] || [ "$has_options" = false ]; then
      av1_test
    fi

    if [ "$only_webp" = true ] || [ "$only_csv" = true ] || [ "$has_options" = false ]; then
      webp_near_lossless
    fi

    if [ "$only_webp_lossy" = true ] || [ "$only_csv" = true ] || [ "$has_options" = false ]; then
      webp_lossy
    fi

    if [ "$only_bpg_lossy" = true ] || [ "$only_csv" = true ] || [ "$has_options" = false ]; then
      bpg_lossy
    fi

    if [ "$only_bpg_lossy_jctvc" = true ] || [ "$only_csv" = true ] || [ "$has_options" = false ]; then
      bpg_lossy_jctvc
    fi

    if [ "$only_flif_lossy" = true ] || [ "$only_csv" = true ] || [ "$has_options" = false ]; then
      flif_lossy
    fi


    #plot the graphs
    echo "Generating the plots[Source :$x]"
    rm -rf "$filename"_butteraugli_plot.png "$filename"_ssimulacra_plot.png
    plotcsv_graph "$filename"_butteraugli_plot.png "$filename"  "Source: $filename"
    plotcsv_graph_ssimulacra "$filename"_ssimulacra_plot.png  "$filename" "Source: $filename"
    files_to_zip+=("libjpeg-${filename}.csv" "libjpeg2000-${filename}.csv" "guetzli-${filename}.csv" "pik-${filename}.csv" "av1-${filename}.csv" "webp-${filename}.csv" "webp_lossy-${filename}.csv"  "bpg-${filename}.csv" "flif_lossy-${filename}.csv" "mozjpeg-${filename}.csv" "bpg_jctvc-${filename}.csv" "${filename}_butteraugli_plot.png" "${filename}_ssimulacra_plot.png")
    list_pik+=("pik-${filename}.csv")
    list_libjpeg+=("libjpeg-${filename}.csv")
    list_libjpeg2000+=("libjpeg2000-${filename}.csv")
    list_guetzli+=("guetzli-${filename}.csv")
    list_flif_lossy+=("flif_lossy-${filename}.csv")
    list_bpg+=("bpg-${filename}.csv")
    list_bpg_jctvc+=("bpg_jctvc-${filename}.csv")
    list_mozjpeg+=("mozjpeg-${filename}.csv")
    list_av1+=("av1-${filename}.csv")
    list_webp+=("webp-${filename}.csv")
    list_webp_lossy+=("webp_lossy-${filename}.csv")

    #Generate heatmap + comparison csv if option is present
    if [ "$target_size" -gt 0 ]; then
	 
	  if [ ! -e "pik-$filename.csv" ]; then
			echo "Pik CSV file doesn't exist! Regenerating csv"
			pik_test
	  fi
	  
	  if [ ! -e "libjpeg-$filename.csv" ]; then
			echo "LibJPEG CSV file doesn't exist! Regenerating csv"
			libjpeg_test
	  fi
	  
	  if [ ! -e "libjpeg2000-$filename.csv" ]; then
			echo "LibJPEG 2000 CSV file doesn't exist! Regenerating csv"
			libjpeg_2000_test
	  fi
	  
	  if [ ! -e "guetzli-$filename.csv" ]; then
			echo "Guetzli CSV file doesn't exist! Regenerating csv"
			guetzli_test
	  fi
	  
	  if [ ! -e "flif_lossy-$filename.csv" ]; then
			echo "Flif_lossy CSV file doesn't exist! Regenerating csv"
			flif_lossy
	  fi
	  
	  if [ ! -e "bpg-$filename.csv" ]; then
			echo "BPG_lossy CSV file doesn't exist! Regenerating csv"
			bpg_lossy
	  fi
	  
	  if [ ! -e "bpg_jctvc-$filename.csv" ]; then
			echo "BPG_lossy CSV file doesn't exist! Regenerating csv"
			bpg_lossy_jctvc
	  fi
	  
	  if [ ! -e "mozjpeg-$filename.csv" ]; then
			echo "MozJPEG CSV file doesn't exist! Regenerating csv"
			mozjpeg_test
	  fi
	  
	  if [ ! -e "av1-$filename.csv" ]; then
			echo "AV1 CSV file doesn't exist! Regenerating csv"
			av1_test
	  fi
	  
	  if [ ! -e "webp-$filename.csv" ]; then
			echo "Webp CSV file doesn't exist! Regenerating csv"
			webp_near_lossless
	  fi
	  
	  if [ ! -e "webp_lossy-$filename.csv" ]; then
			echo "Webp lossy CSV file file doesn't exist! Regenerating csv"
			webp_lossy
	  fi

      echo "Generating heatmaps + comparision csv"
      echo "Encoder,Quality,Size(bytes),Size(bpp),Butteraugli,Ssimulacra,Compression Rate(%),Reference Compression Rate(%)" >> comparision-"$filename".csv

      #pik
      while read -r line
      do
        i=$(echo "$line" | cut -d',' -f1) #get quality
        new_size=$(echo "$line" | cut -d',' -f2) #get size
        new_size_bpp=$(echo "$line" | cut -d',' -f3)
        butteraugli_score=$(echo "$line" | cut -d',' -f4)
        ssimulacra_score=$(echo "$line" | cut -d',' -f5)
        compression_rate=$(echo "$line" | cut -d',' -f6)
        reference_compression_rate=$(echo "$line" | cut -d',' -f7)
        #New size >= target_size
        if [ "$new_size" -ge "$target_size" ]; then
          butteraugli_score=$(butteraugli "$x" "$filename"_pik_q"$i".png "$filename"_pik_q"$i"_hm.ppm)
          convert "$filename"_pik_q"$i"_hm.ppm "$filename"_pik_q"$i"_hm.png
          files_to_zip+=("${filename}_pik_q${i}_hm.png" "${filename}_pik_q${i}.png")
          echo "Pik","$i","$new_size","$new_size_bpp","$butteraugli_score","$ssimulacra_score","$compression_rate","$reference_compression_rate" >> comparision-"$filename".csv
          break
        fi
      done < <(tac "pik-$filename.csv" | head -n -3)

      #libjpeg
      while read -r line
      do
        i=$(echo "$line" | cut -d',' -f1) #get quality
        new_size=$(echo "$line" | cut -d',' -f2) #get size
        new_size_bpp=$(echo "$line" | cut -d',' -f3)
        butteraugli_score=$(echo "$line" | cut -d',' -f4)
        ssimulacra_score=$(echo "$line" | cut -d',' -f5)
        compression_rate=$(echo "$line" | cut -d',' -f6)
        reference_compression_rate=$(echo "$line" | cut -d',' -f7)
        #New size >= target_size
        if [ "$new_size" -ge "$target_size" ]; then
          butteraugli_score=$(butteraugli "$x" "$filename"_libjpeg_q"$i".jpg "$filename"_libjpeg_q"$i"_hm.ppm)
          convert "$filename"_libjpeg_q"$i"_hm.ppm "$filename"_libjpeg_q"$i"_hm.png
          files_to_zip+=("${filename}_libjpeg_q${i}_hm.png" "${filename}_libjpeg_q${i}.jpg") 
          echo "LibJPEG","$i","$new_size","$new_size_bpp","$butteraugli_score","$ssimulacra_score","$compression_rate","$reference_compression_rate" >> comparision-"$filename".csv
          break
        fi
      done < <(tac "libjpeg-$filename.csv" | head -n -3) 

      #libjpeg2000
      while read -r line
      do
        i=$(echo "$line" | cut -d',' -f1) #get quality
        new_size=$(echo "$line" | cut -d',' -f2) #get size
        new_size_bpp=$(echo "$line" | cut -d',' -f3)
        butteraugli_score=$(echo "$line" | cut -d',' -f4)
        ssimulacra_score=$(echo "$line" | cut -d',' -f5)
        compression_rate=$(echo "$line" | cut -d',' -f6)
        reference_compression_rate=$(echo "$line" | cut -d',' -f7)
        #New size >= target_size
        if [ "$new_size" -ge "$target_size" ]; then
          butteraugli_score=$(butteraugli "$x" "$filename"_openjpeg_q"$i".png "$filename"_openjpeg_q"$i"_hm.ppm)
          convert "$filename"_openjpeg_q"$i"_hm.ppm "$filename"_openjpeg_q"$i"_hm.png
          files_to_zip+=("${filename}_openjpeg_q${i}_hm.png" "${filename}_openjpeg_q${i}.png")
          echo "OpenJPEG","$i","$new_size","$new_size_bpp","$butteraugli_score","$ssimulacra_score","$compression_rate","$reference_compression_rate" >> comparision-"$filename".csv
          break
        fi
      done < <(tac "libjpeg2000-$filename.csv" | head -n -3) 

      #guetzli
      while read -r line
      do
        i=$(echo "$line" | cut -d',' -f1) #get quality
        new_size=$(echo "$line" | cut -d',' -f2) #get size
        new_size_bpp=$(echo "$line" | cut -d',' -f3)
        butteraugli_score=$(echo "$line" | cut -d',' -f4)
        ssimulacra_score=$(echo "$line" | cut -d',' -f5)
        compression_rate=$(echo "$line" | cut -d',' -f6)
        reference_compression_rate=$(echo "$line" | cut -d',' -f7)
        #New size >= target_size
        if [ "$new_size" -ge "$target_size" ]; then
          butteraugli_score=$(butteraugli "$x" "$filename"_guetzli_q"$i".jpg "$filename"_guetzli_q"$i"_hm.ppm)
          convert "$filename"_guetzli_q"$i"_hm.ppm "$filename"_guetzli_q"$i"_hm.png
          files_to_zip+=("${filename}_guetzli_q${i}_hm.png" "${filename}_guetzli_q${i}.jpg")
          echo "Guetzli","$i","$new_size","$new_size_bpp","$butteraugli_score","$ssimulacra_score","$compression_rate","$reference_compression_rate" >> comparision-"$filename".csv
          break
        fi
      done < <(tac "guetzli-$filename.csv" | head -n -3) 

      #flif_lossy
      while read -r line
      do
        i=$(echo "$line" | cut -d',' -f1) #get quality
        new_size=$(echo "$line" | cut -d',' -f2) #get size
        new_size_bpp=$(echo "$line" | cut -d',' -f3)
        butteraugli_score=$(echo "$line" | cut -d',' -f4)
        ssimulacra_score=$(echo "$line" | cut -d',' -f5)
        compression_rate=$(echo "$line" | cut -d',' -f6)
        reference_compression_rate=$(echo "$line" | cut -d',' -f7)
        #New size >= target_size
        if [ "$new_size" -ge "$target_size" ]; then
          butteraugli_score=$(butteraugli "$x" "$filename"_flif_lossy_q"$i".png "$filename"_flif_lossy_q"$i"_hm.ppm)
          convert "$filename"_flif_lossy_q"$i"_hm.ppm "$filename"_flif_lossy_q"$i"_hm.png
          files_to_zip+=("${filename}_flif_lossy_q${i}_hm.png"  "${filename}_flif_lossy_q${i}.png")
          echo "Flif Lossy","$i","$new_size","$new_size_bpp","$butteraugli_score","$ssimulacra_score","$compression_rate","$reference_compression_rate" >> comparision-"$filename".csv
          break
        fi
      done < <(tac "flif_lossy-$filename.csv" | head -n -3) 

      #bpg
      while read -r line
      do
        i=$(echo "$line" | cut -d',' -f1) #get quality
        new_size=$(echo "$line" | cut -d',' -f2) #get size
        new_size_bpp=$(echo "$line" | cut -d',' -f3)
        butteraugli_score=$(echo "$line" | cut -d',' -f4)
        ssimulacra_score=$(echo "$line" | cut -d',' -f5)
        compression_rate=$(echo "$line" | cut -d',' -f6)
        reference_compression_rate=$(echo "$line" | cut -d',' -f7)
        #New size >= target_size
        if [ "$new_size" -ge "$target_size" ]; then
          butteraugli_score=$(butteraugli "$x" "$filename"_bpg_q"$i".png "$filename"_bpg_q"$i"_hm.ppm)
          convert "$filename"_bpg_q"$i"_hm.ppm "$filename"_bpg_q"$i"_hm.png
          files_to_zip+=("${filename}_bpg_q${i}_hm.png" "${filename}_bpg_q${i}.png")
          echo "BPG(x265) Lossy","$i","$new_size","$new_size_bpp","$butteraugli_score","$ssimulacra_score","$compression_rate","$reference_compression_rate" >> comparision-"$filename".csv
          break
        fi
      done < <(tac "bpg-$filename.csv" | head -n -3) 

      #bpg jctvc
      while read -r line
      do
        i=$(echo "$line" | cut -d',' -f1) #get quality
        new_size=$(echo "$line" | cut -d',' -f2) #get size
        new_size_bpp=$(echo "$line" | cut -d',' -f3)
        butteraugli_score=$(echo "$line" | cut -d',' -f4)
        ssimulacra_score=$(echo "$line" | cut -d',' -f5)
        compression_rate=$(echo "$line" | cut -d',' -f6)
        reference_compression_rate=$(echo "$line" | cut -d',' -f7)
        #New size >= target_size
        if [ "$new_size" -ge "$target_size" ]; then
          butteraugli_score=$(butteraugli "$x" "$filename"_bpg_jctvc_q"$i".png "$filename"_bpg_jctvc_q"$i"_hm.ppm)
          convert "$filename"_bpg_jctvc_q"$i"_hm.ppm "$filename"_bpg_jctvc_q"$i"_hm.png
          files_to_zip+=("${filename}_bpg_jctvc_q${i}_hm.png" "${filename}_bpg_jctvc_q${i}.png")
          echo "BPG(jctvc) Lossy","$i","$new_size","$new_size_bpp","$butteraugli_score","$ssimulacra_score","$compression_rate","$reference_compression_rate" >> comparision-"$filename".csv
          break
        fi
      done < <(tac "bpg_jctvc-$filename.csv" | head -n -3)

      #mozjpeg
      while read -r line
      do
        i=$(echo "$line" | cut -d',' -f1) #get quality
        new_size=$(echo "$line" | cut -d',' -f2) #get size
        new_size_bpp=$(echo "$line" | cut -d',' -f3)
        butteraugli_score=$(echo "$line" | cut -d',' -f4)
        ssimulacra_score=$(echo "$line" | cut -d',' -f5)
        compression_rate=$(echo "$line" | cut -d',' -f6)
        reference_compression_rate=$(echo "$line" | cut -d',' -f7)
        #New size >= target_size
        if [ "$new_size" -ge "$target_size" ]; then
		  butteraugli_score=$(butteraugli "$x" "$filename"_mozjpeg_q"$i".jpg "$filename"_mozjpeg_q"$i"_hm.ppm)
          convert "$filename"_mozjpeg_q"$i"_hm.ppm  "$filename"_mozjpeg_q"$i"_hm.png
          files_to_zip+=("${filename}_mozjpeg_q${i}_hm.png" "${filename}_mozjpeg_q${i}.jpg")
          echo "MozJPEG","$i","$new_size","$new_size_bpp","$butteraugli_score","$ssimulacra_score","$compression_rate","$reference_compression_rate" >> comparision-"$filename".csv
          break
        fi
      done < <(tac "mozjpeg-$filename.csv" | head -n -3)

      #av1
      while read -r line
      do
		q=$(echo "$line" | cut -d',' -f1) 
		i=$(echo "$line" | cut -d',' -f2)
		new_size=$(echo "$line" | cut -d',' -f3) #get size
		new_size_bpp=$(echo "$line" | cut -d',' -f4)
		butteraugli_score=$(echo "$line" | cut -d',' -f5)
		ssimulacra_score=$(echo "$line" | cut -d',' -f6)
		compression_rate=$(echo "$line" | cut -d',' -f7)
		reference_compression_rate=$(echo "$line" | cut -d',' -f8)
      #New size >= target_size
      if [ "$new_size" -ge "$target_size" ]; then
		butteraugli_score=$(butteraugli "$x" "$x"_"$i"_"$q".png "$x"_"$i"_"$q"_hm.ppm)
		convert "$x"_"$i"_"$q"_hm.ppm "$x"_"$i"_"$q"_hm.png
		files_to_zip+=("${x}_${i}_${q}_hm.png" "${x}_${i}_${q}.png")
		echo "AV1","$q-$i","$new_size","$new_size_bpp","$butteraugli_score","$ssimulacra_score","$compression_rate","$reference_compression_rate" >> comparision-"$filename".csv
		break
      fi
      done < <(tac "av1-$filename.csv" | head -n -3 | sort  -k3 -n -t,)


      #webp lossy
      while read -r line
      do
        i=$(echo "$line" | cut -d',' -f1) #get quality
        new_size=$(echo "$line" | cut -d',' -f2) #get size
        new_size_bpp=$(echo "$line" | cut -d',' -f3)
        butteraugli_score=$(echo "$line" | cut -d',' -f4)
        ssimulacra_score=$(echo "$line" | cut -d',' -f5)
        compression_rate=$(echo "$line" | cut -d',' -f6)
        reference_compression_rate=$(echo "$line" | cut -d',' -f7)
        #New size >= target_size
        if [ "$new_size" -ge "$target_size" ]; then
          butteraugli_score=$(butteraugli "$x" "$filename"_webp_lossy_q"$i".png "$filename"_webp_lossy_q"$i"_hm.ppm)
          convert "$filename"_webp_lossy_q"$i"_hm.ppm "$filename"_webp_lossy_q"$i"_hm.png
          files_to_zip+=("${filename}_webp_lossy_q${i}.png" "${filename}_webp_lossy_q${i}_hm.png")
          echo "Webp(Lossy)","$i","$new_size","$new_size_bpp","$butteraugli_score","$ssimulacra_score","$compression_rate","$reference_compression_rate" >> comparision-"$filename".csv
          break
        fi
      done < <(tac "webp_lossy-$filename.csv" | head -n -3)


      #webp
      while read -r line
      do
        i=$(echo "$line" | cut -d',' -f1) #get quality
        new_size=$(echo "$line" | cut -d',' -f2) #get size
        new_size_bpp=$(echo "$line" | cut -d',' -f3)
        butteraugli_score=$(echo "$line" | cut -d',' -f4)
        ssimulacra_score=$(echo "$line" | cut -d',' -f5)
        compression_rate=$(echo "$line" | cut -d',' -f6)
        reference_compression_rate=$(echo "$line" | cut -d',' -f7)
        #New size >= target_size
        if [ "$new_size" -ge "$target_size" ]; then
          butteraugli_score=$(butteraugli "$x" "$filename"_webp_q"$i".png "$filename"_webp_q"$i"_hm.ppm)
          convert "$filename"_webp_q"$i"_hm.ppm "$filename"_webp_q"$i"_hm.png
          files_to_zip+=("${filename}_webp_q${i}.png" "${filename}_webp_q${i}_hm.png")
          echo "Webp","$i","$new_size","$new_size_bpp","$butteraugli_score","$ssimulacra_score","$compression_rate","$reference_compression_rate" >> comparision-"$filename".csv
          break
        fi
      done < <(tac "webp-$filename.csv" | head -n -3)

      sort  -k3 -n -t, comparision-"$filename".csv -o comparision-"$filename".csv # sort the csv by filesize
      files_to_zip+=("comparision-$filename.csv")

    fi

  done

  if [ "$combine_plots" = true ]; then
    rm -rf pik-merge.csv libjpeg-merge.csv libjpeg2000-merge.csv guetzli-merge.csv flif_lossy-merge.csv bpg-merge.csv bpg_jctvc-merge.csv mozjpeg-merge.csv mozjpeg-merge.csv av1-merge.csv webp-merge.csv webp_lossy-merge.csv butteraugli_plot_merge.png ssimulacra_merge ssimulacra_plot_merge.png
	#Create the merge csv
	tail -q -n +4  "${list_pik[@]}" | datamash -st, -g1 mean 3  mean 4 mean 5 | awk -F , '{printf ("%s,%.2f,%.6f,%.8f\n",$1,$2,$3,$4)}'  &> pik-merge.csv
    tail -q -n +4  "${list_libjpeg[@]}" | datamash -st, -g1 mean 3  mean 4 mean 5 | awk -F , '{printf ("%s,%.2f,%.6f,%.8f\n",$1,$2,$3,$4)}' |  sort -k1,1 -r -n -t, &> libjpeg-merge.csv
    tail -q -n +4  "${list_libjpeg2000[@]}" | datamash -st, -g1 mean 3  mean 4 mean 5 | awk -F , '{printf ("%s,%.2f,%.6f,%.8f\n",$1,$2,$3,$4)}' | sort -k1,1 -r -n -t, &> libjpeg2000-merge.csv
    tail -q -n +4  "${list_guetzli[@]}" | datamash -st, -g1 mean 3  mean 4 mean 5 | awk -F , '{printf ("%s,%.2f,%.6f,%.8f\n",$1,$2,$3,$4)}' | sort -k1,1 -r -n -t, &> guetzli-merge.csv
    tail -q -n +4  "${list_flif_lossy[@]}" | datamash -st, -g1 mean 3  mean 4 mean 5 | awk -F , '{printf ("%s,%.2f,%.6f,%.8f\n",$1,$2,$3,$4)}' | sort -k1,1 -r -n -t, &> flif_lossy-merge.csv
    tail -q -n +4  "${list_bpg[@]}"  | datamash -st, -g1 mean 3  mean 4 mean 5 | awk -F , '{printf ("%s,%.2f,%.6f,%.8f\n",$1,$2,$3,$4)}' | sort -k1,1 -r -n -t, &> bpg-merge.csv
    tail -q -n +4  "${list_bpg_jctvc[@]}" | datamash -st, -g1 mean 3  mean 4 mean 5 | awk -F , '{printf ("%s,%.2f,%.6f,%.8f\n",$1,$2,$3,$4)}' | sort -k1,1 -r -n -t, &> bpg_jctvc-merge.csv
    tail -q -n +4  "${list_mozjpeg[@]}" | datamash -st, -g1 mean 3  mean 4 mean 5 | awk -F , '{printf ("%s,%.2f,%.6f,%.8f\n",$1,$2,$3,$4)}' | sort -k1,1 -r -n -t, &> mozjpeg-merge.csv
    tail -q -n +4  "${list_av1[@]}" | datamash -st, -g1,2 mean 4  mean 5 mean 6 | awk -F , '{printf ("%s,%s,%.2f,%.6f,%.8f\n",$1,$2,$3,$4,$5)}' | sort -k1,1 -k2,2 -n  -t,  &> av1-merge.csv 
    tail -q -n +4  "${list_webp[@]}" | datamash -st, -g1 mean 3  mean 4 mean 5 | awk -F , '{printf ("%s,%.2f,%.6f,%.8f\n",$1,$2,$3,$4)}' | sort -k1,1 -r -n -t, &> webp-merge.csv
    tail -q -n +4  "${list_webp_lossy[@]}"  | datamash -st, -g1 mean 3  mean 4 mean 5 | awk -F , '{printf ("%s,%.2f,%.6f,%.8f\n",$1,$2,$3,$4)}' | sort -k1,1 -r -n -t, &> webp_lossy-merge.csv
	
	
    plotcsv_graph_merge butteraugli_plot_merge.png "Merge Butteraugli Plot( ${image_count} images )"
    plotcsv_graph_ssimulacra_merge ssimulacra_plot_merge.png  "Merge Ssimulacra Plot( ${image_count} images )"
    files_to_zip+=("butteraugli_plot_merge.png" "ssimulacra_plot_merge.png" "pik-merge.csv" "libjpeg-merge.csv" "libjpeg2000-merge.csv" "guetzli-merge.csv" "flif_lossy-merge.csv" "bpg-merge.csv" "bpg_jctvc-merge.csv" "mozjpeg-merge.csv" "mozjpeg-merge.csv" "av1-merge.csv" "webp-merge.csv" "webp_lossy-merge.csv")
  fi



  #Create a zip to store the results
  zipfile_name=result_corpus_with_plots$(date "+%Y.%m.%d-%H.%M.%S").zip
  zip "$zipfile_name" "${files_to_zip[@]}"
  current_dir=$(pwd)/"$zipfile_name"
  echo "Success! Download results : $current_dir"
}

main "$@"
