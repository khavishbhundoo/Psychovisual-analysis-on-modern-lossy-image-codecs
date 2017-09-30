#!/bin/bash
#
#####################################################
#                                                   #
# Author : Khavish Anshudass Bhundoo                #
# License : MIT                                     #
# Performs compression tests using multiple encoders#
#####################################################

#TODO : Taking a butteraugli score of 1.0 as a reference, generate a heatmap of each codec that is just above that byte size

function exists()
{
  command -v "$1" >/dev/null 2>&1
}

function usage()
{
  echo "Usage: $(basename "${BASH_SOURCE}") [options] image1.png image2.png ..."
  echo "Main Options"
  echo "--only-pik              Redo the test[image generation + csv ] only for pik and regenerate plots"
  echo "--only-libjpeg          Redo the test[image generation + csv ] only for libjpeg and regenerate plots"
  echo "--only-libjpeg-2000     Redo the test[image generation + csv ] only for libjpeg 2000 and regenerate plots"
  echo "--only-guetzli          Redo the test[image generation + csv ] only for guezli and regenerate plots"
  echo "--only-flif-lossy       Redo the test[image generation + csv ] only for flif(lossy) and regenerate plots"
  echo "--only-webp             Redo the test[image generation + csv ] only for webp(near-lossless) and regenerate plots"
  echo "--only-webp-lossy       Redo the test[image generation + csv ] only for webp(lossy) and regenerate plots"
  echo "--only-bpg-lossy        Redo the test[image generation + csv ] only for bgp(lossy) and regenerate plots"
  echo "--only-bpg-lossy-jctvc  Redo the test[image generation + csv ] only for bgp(lossy) and regenerate plots"
  echo "--only-mozjpeg          Redo the test[image generation + csv ] only for mozjpeg and regenerate plots"
  echo "--only-av1              Redo the test[image generation + csv ] only for av1 and regenerate plots"
  echo "--only-plots            Only regenerate plots"
  echo "--only-csv              Only regenerate csv files and plots"
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

  if ! exists parallel; then
    echo 'gnu parallel is not installed...exiting'
    missing_deps=true
  fi

  if [ "$missing_deps" = true ] ; then
    exit 1
  fi


}

function plotcsv_graph
{
  gnuplot -persist <<-EOFMarker
    set terminal pngcairo size 1280,1024 enhanced font "Helvetica,20"
    # line styles
    set style line 1 lt 1 lw 5 lc rgb '#D53E4F' ps 0 # red
    set style line 2 lt 1 lw 5 lc rgb '#F46D43' ps 0 # orange
    set style line 3 lt 1 lw 5 lc rgb '#FDAE61' ps 0 # pale orange
    set style line 4 lt 1 lw 5 lc rgb '#FEE08B' ps 0 # pale yellow-orange
    set style line 5 lt 1 lw 5 lc rgb '#E6F598' ps 0 # pale yellow-green
    set style line 6 lt 1 lw 5 lc rgb '#ABDDA4' ps 0 # pale green
    set style line 7 lt 1 lw 5 lc rgb '#66C2A5' ps 0 # green
    set style line 8 lt 1 lw 5 lc rgb '#3288BD' ps 0 # blue
	set style line 9 lt 1 lw 5 lc rgb '#6D32BD' ps 0 # purple
	set style line 10 lt 1 lw 5 lc rgb '#77776e' ps 0 # grey
    set style line 11 lt 1 lw 5 lc rgb '#914d8f' ps 0 # pink
    set tics nomirror
	set ytics 1
	set mytics 10
    set output "$1"
	set title  "$3"
    set xlabel 'bytesize'
    set ylabel 'butteraugli score'
	set style func linespoints
	set datafile separator ","
	set xtics font ", 12"
	set arrow from $reference_jpg_size, graph 0 to $reference_jpg_size, graph 1 nohead lt 0
	plot "pik-$2.csv" using 2:3 w lp ls 3 title 'pik', \
    "libjpeg-$2.csv" using 2:3 w lp ls 4 title 'libjpeg', \
	"libjpeg-2000-$2.csv" using 2:3 w lp ls 10 title 'JPEG 2000', \
    "guetzli-$2.csv" using 2:3 w lp ls 5 title 'guetzli', \
    "flif-lossy-$2.csv" using 2:3 w lp ls 6 title 'flif-lossy', \
	"bpg-$2.csv" using 2:3 w lp ls 7 title 'bpg(x265)', \
	"bpg-jctvc-$2.csv" using 2:3 w lp ls 8 title 'bpg(jctvc)', \
	"mozjpeg-$2.csv" using 2:3 w lp ls 9 title 'MozJPEG', \
	"av1-$2.csv" using 3:4 w lp ls 11 title 'AV1', \
	"webp-$2.csv" using 2:3 w lp ls 1 title 'webp-near-lossless-40/60', \
	"webp-lossy-$2.csv" using 2:3 w lp ls 2 title 'webp-lossy', \
	1/0 t "Reference Size" lt 0
EOFMarker
}

function plotcsv_graph_ssimulacra
{
  gnuplot -persist <<-EOFMarker
    set terminal pngcairo size 1280,1024 enhanced font "Helvetica,20"
    # line styles
    set style line 1 lt 1 lw 5 lc rgb '#D53E4F' ps 0 # red
    set style line 2 lt 1 lw 5 lc rgb '#F46D43' ps 0 # orange
    set style line 3 lt 1 lw 5 lc rgb '#FDAE61' ps 0 # pale orange
    set style line 4 lt 1 lw 5 lc rgb '#FEE08B' ps 0 # pale yellow-orange
    set style line 5 lt 1 lw 5 lc rgb '#E6F598' ps 0 # pale yellow-green
    set style line 6 lt 1 lw 5 lc rgb '#ABDDA4' ps 0 # pale green
    set style line 7 lt 1 lw 5 lc rgb '#66C2A5' ps 0 # green
    set style line 8 lt 1 lw 5 lc rgb '#3288BD' ps 0 # blue
	set style line 9 lt 1 lw 5 lc rgb '#6D32BD' ps 0 # purple
	set style line 10 lt 1 lw 5 lc rgb '#77776e' ps 0 # grey
    set style line 11 lt 1 lw 5 lc rgb '#914d8f' ps 0 # pink
    set tics nomirror
	set ytics 0.01
	set mytics 10
    set output "$1"
	set title  "$3"
    set xlabel 'bytesize'
    set ylabel 'ssimulacra score'
	set style func linespoints
	set datafile separator ","
	set xtics font ", 12"
	set arrow from $reference_jpg_size, graph 0 to $reference_jpg_size, graph 1 nohead lt 0
	plot "pik-$2.csv" using 2:4 w lp ls 3 title 'pik', \
    "libjpeg-$2.csv" using 2:4 w lp ls 4 title 'libjpeg', \
	"libjpeg-2000-$2.csv" using 2:4 w lp ls 10 title 'JPEG 2000', \
    "guetzli-$2.csv" using 2:4 w lp ls 5 title 'guetzli', \
    "flif-lossy-$2.csv" using 2:4 w lp ls 6 title 'flif-lossy', \
	"bpg-$2.csv" using 2:4 w lp ls 7 title 'bpg(x265)', \
	"bpg-jctvc-$2.csv" using 2:4 w lp ls 8 title 'bpg(jctvc)', \
	"mozjpeg-$2.csv" using 2:4 w lp ls 9 title 'MozJPEG', \
	"av1-$2.csv" using 3:5 w lp ls 11 title 'AV1', \
	"webp-$2.csv" using 2:4 w lp ls 1 title 'webp-near-lossless-40/60', \
	"webp-lossy-$2.csv" using 2:4 w lp ls 2 title 'webp-lossy', \
	1/0 t "Reference Size" lt 0
EOFMarker
}



function libjpeg_test
{
  echo "Analysing JPEGs optimized by LibJPEG[Source :$x]"
  rm -rf libjpeg-"$filename".csv
  #Start csv generation
  echo "Test_Image,Original_Size" >> libjpeg-"$filename".csv
  echo "$filename","$orig_size" >> libjpeg-"$filename".csv
  echo "Quality,Size(bytes),Butteraugli,Ssimulacra,Compression Rate(%),Reference Compression Rate(%)" >> libjpeg-"$filename".csv
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
    #jpeg -q "$i" -oz -v -qt 2 -h  "$x".ppm "$filename"_libjpeg_q"$i".jpg
    new_size=$(wc -c < "$filename"_libjpeg_q"$i".jpg)
    butteraugli_score=$(butteraugli "$x" "$filename"_libjpeg_q"$i".jpg)
    ssimulacra_score=$(ssimulacra "$x" "$filename"_libjpeg_q"$i".jpg)
    compression_rate=$(echo "(($orig_size - $new_size) / $orig_size) * 100" | bc -l)
    reference_compression_rate=$(echo "(($reference_jpg_size - $new_size) / $reference_jpg_size) * 100" | bc -l)
    printf -v compression_rate "%0.2f" "$compression_rate" #set to 2 dp
    printf -v reference_compression_rate "%0.2f" "$reference_compression_rate" #set to 2 dp
    echo "$i","$new_size","$butteraugli_score","$ssimulacra_score","$compression_rate","$reference_compression_rate" >> libjpeg-"$filename".csv
  done
#End csv generation
}

#need to complete
function av1_test
{
  echo "Analysing images optimized by AV1"
  rm -rf av1-"$filename".csv "$x".y4m
  ffmpeg -nostats -loglevel 0 -y -i  "$x" -pix_fmt yuv444p10le -strict -2 "$x".y4m
  width=$(identify -format "%w" "$x")
  height=$(identify -format "%h" "$x")
  #Start csv generation
  echo "Test_Image,Original_Size" >> av1-"$filename".csv
  echo "$filename","$orig_size" >> av1-"$filename".csv
  echo "Quality(cq-level),Flatness(qm-min),Size(bytes),Butteraugli,Ssimulacra,Compression Rate(%),Reference Compression Rate(%)" >> av1-"$filename".csv
  for q in 10 12 14 16 18 20 22 24 26 28 30; do
    for i in 4 6 8 10 12; do
      if [ "$only_csv" = false ]; then
        aomenc "$x".y4m --i444 --enable-qm=1 --qm-min="$i" --profile=3 -w "$width" -h "$height" -b 10 --end-usage=q --cq-level="$q" -o "$x"_"$i"_"$q".ivf
        aomdec "$x"_"$i"_"$q".ivf --output-bit-depth=10 -o "$x"_"$i"_"$q".y4m
        ffmpeg -nostats -loglevel 0 -y -i "$x"_"$i"_"$q".y4m "$x"_"$i"_"$q".png
        convert "$x"_"$i"_"$q".png PNG24:"$x"_"$i"_"$q"_ssimulacra.png # ssimulacra can't handle generated png
      fi
      new_size=$(wc -c < "$x"_"$i"_"$q".ivf)
      butteraugli_score=$(butteraugli "$x" "$x"_"$i"_"$q".png)
      ssimulacra_score=$(ssimulacra "$x" "$x"_"$i"_"$q"_ssimulacra.png)
      compression_rate=$(echo "(($orig_size - $new_size) / $orig_size) * 100" | bc -l)
      reference_compression_rate=$(echo "(($reference_jpg_size - $new_size) / $reference_jpg_size) * 100" | bc -l)
      printf -v compression_rate "%0.2f" "$compression_rate" #set to 2 dp
      printf -v reference_compression_rate "%0.2f" "$reference_compression_rate" #set to 2 dp
      echo "$q","$i","$new_size","$butteraugli_score","$ssimulacra_score","$compression_rate","$reference_compression_rate" >> av1-"$filename".csv
    done
  done
#End csv generation
}

function libjpeg_2000_test
{
  echo "Analysing JPEG 2000 images optimized by OpenJPEG(JPEG 2000)[Source :$x]"
  rm -rf libjpeg-2000-"$filename".csv
  #Start csv generation
  echo "Test_Image,Original_Size" >> libjpeg-2000-"$filename".csv
  echo "$filename","$orig_size" >> libjpeg-2000-"$filename".csv
  echo "Quality,Size(bytes),Butteraugli,Ssimulacra,Compression Rate(%),Reference Compression Rate(%)" >> libjpeg-2000-"$filename".csv
  if [ "$only_csv" = false ]; then
    echo "Generating JPEG 2000 images optimized by LibJPEG[Source :$x] in parallel"
    parallel --will-cite 'opj_compress -i "{1}".ppm -r "{2}" -o "{3}"_openjpeg_q"{2}".jp2 -I -r "{2}"' ::: "$x" ::: {0..25}  ::: "$filename"
    parallel --will-cite 'opj_decompress -i "{3}"_openjpeg_q"{2}".jp2  -o "{3}"_openjpeg_q"{2}".png' ::: "$x" ::: {0..25}  ::: "$filename"
  fi
  echo "Perform comparisions and store results in libjpeg-2000-$filename.csv"
  for ((i=0; i<=25; i++))
  do
    #opj_compress -i "$x".ppm -r "$i" -o "$filename"_openjpeg_q"$i".jp2 -I -r "$i"
    #opj_decompress -i "$filename"_openjpeg_q"$i".jp2  -o "$filename"_openjpeg_q"$i".png
    new_size=$(wc -c < "$filename"_openjpeg_q"$i".jp2)
    butteraugli_score=$(butteraugli "$x" "$filename"_openjpeg_q"$i".png)
    ssimulacra_score=$(ssimulacra "$x" "$filename"_openjpeg_q"$i".png)
    compression_rate=$(echo "(($orig_size - $new_size) / $orig_size) * 100" | bc -l)
    reference_compression_rate=$(echo "(($reference_jpg_size - $new_size) / $reference_jpg_size) * 100" | bc -l)
    printf -v compression_rate "%0.2f" "$compression_rate" #set to 2 dp
    printf -v reference_compression_rate "%0.2f" "$reference_compression_rate" #set to 2 dp
    echo "$i","$new_size","$butteraugli_score","$ssimulacra_score","$compression_rate","$reference_compression_rate" >> libjpeg-2000-"$filename".csv
  done
#End csv generation
}

function guetzli_test
{
  echo "Analysing JPEGs optimized by Guetzli[Source :$x]"
  rm -rf guetzli-"$filename".csv
#Start csv generation
  echo "Test_Image,Original_Size" >> guetzli-"$filename".csv
  echo "$filename","$orig_size" >> guetzli-"$filename".csv
  echo "Quality,Size(bytes),Butteraugli,Ssimulacra,Compression Rate(%),Reference Compression Rate(%)" >> guetzli-"$filename".csv
  if [ "$only_csv" = false ]; then
    echo "Generating JPEGs optimized by Guetzli(This will take a while...BE patient)[Source :$x] in parallel"
    parallel --will-cite 'guetzli --nomemlimit --quality "{2}"  "{1}"  "{3}"_guetzli_q"{2}".jpg' ::: "$x" ::: {100..84} ::: "$filename"
  fi
  echo "Perform comparisions and store results in guetzli-$filename.csv"
  for ((i=100; i>=84; i--))
  do
    #guetzli --quality "$i"  "$x"  "$filename"_guetzli_q"$i".jpg
    new_size=$(wc -c < "$filename"_guetzli_q"$i".jpg)
    butteraugli_score=$(butteraugli "$x" "$filename"_guetzli_q"$i".jpg)
    ssimulacra_score=$(ssimulacra "$x" "$filename"_guetzli_q"$i".jpg)
    compression_rate=$(echo "(($orig_size - $new_size) / $orig_size) * 100" | bc -l)
    reference_compression_rate=$(echo "(($reference_jpg_size - $new_size) / $reference_jpg_size) * 100" | bc -l)
    printf -v compression_rate "%0.2f" "$compression_rate" #set to 2 dp
    printf -v reference_compression_rate "%0.2f" "$reference_compression_rate" #set to 2 dp
    echo "$i","$new_size","$butteraugli_score","$ssimulacra_score","$compression_rate","$reference_compression_rate" >> guetzli-"$filename".csv
  done
#End csv generation
}

function mozjpeg_test
{
  rm -rf mozjpeg-"$filename".csv
  echo "Analysing JPEGs optimized by MozJPEG[Source :$x]"
  #Start csv generation
  echo "Test_Image,Original_Size" >> mozjpeg-"$filename".csv
  echo "$filename","$orig_size" >> mozjpeg-"$filename".csv
  echo "Quality,Size(bytes),Butteraugli,Ssimulacra,Compression Rate(%),Reference Compression Rate(%)" >> mozjpeg-"$filename".csv
  if [ "$only_csv" = false ]; then
    echo "Generating JPEGs optimized by MozJPEG[Source :$x] in parallel"
    parallel --will-cite 'cjpeg -optimize -dc-scan-opt 2 -sample 1x1 -quality "{1}" -outfile "{2}"_mozjpeg_q{1}.jpg {3}' ::: {100..70}  ::: "$filename" ::: "$x"
  fi
  echo "Perform comparisions and store results in mozjpeg-$filename.csv"
  for ((i=100; i>=70; i--))
  do
    #cjpeg -optimize -sample 1x1 -quality "$i" -outfile "$filename"_mozjpeg_q"$i".jpg "$x"
    new_size=$(wc -c < "$filename"_mozjpeg_q"$i".jpg)
    butteraugli_score=$(butteraugli "$x" "$filename"_mozjpeg_q"$i".jpg)
    ssimulacra_score=$(ssimulacra "$x" "$filename"_mozjpeg_q"$i".jpg)
    compression_rate=$(echo "(($orig_size - $new_size) / $orig_size) * 100" | bc -l)
    reference_compression_rate=$(echo "(($reference_jpg_size - $new_size) / $reference_jpg_size) * 100" | bc -l)
    printf -v compression_rate "%0.2f" "$compression_rate" #set to 2 dp
    printf -v reference_compression_rate "%0.2f" "$reference_compression_rate" #set to 2 dp
    echo "$i","$new_size","$butteraugli_score","$ssimulacra_score","$compression_rate","$reference_compression_rate" >> mozjpeg-"$filename".csv
  done
#End csv generation
}

function pik_test
{
  echo "Analysing Pik images(This will take a while...BE patient)[Source :$x]"
  rm -rf pik-"$filename".csv
#Start csv generation
  echo "Test_Image,Original_Size" >> pik-"$filename".csv
  echo "$filename","$orig_size" >> pik-"$filename".csv
  echo "Quality,Size(bytes),Butteraugli,Ssimulacra,Compression Rate(%),Reference Compression Rate(%)" >> pik-"$filename".csv
  if [ "$only_csv" = false ]; then
    echo "Generating Pik images(This will take a while...BE patient)[Source :$x] in parallel"
    parallel --will-cite 'cpik "{1}" "{3}"_q"{2}".pik --distance "{2}"' ::: "$x" ::: $(seq 0.6 0.1 3.0) ::: "$filename"
    parallel --will-cite 'dpik "{1}"_q"{2}".pik  "{1}"_pik_q"{2}".png ' ::: "$filename" ::: $(seq 0.6 0.1 3.0)
  fi
  echo "Perform comparisions and store results in pik-$filename.csv"
  for i in $(seq 0.6 0.1 3.0)
  do
    #cpik  "$x" "$filename"_q"$i".pik --distance "$i"
    new_size=$(wc -c < "$filename"_q"$i".pik)
    #convert to png to allow comparision
    #dpik "$filename"_q"$i".pik "$filename"_pik_q"$i".png
    butteraugli_score=$(butteraugli "$x" "$filename"_pik_q"$i".png)
    ssimulacra_score=$(ssimulacra "$x" "$filename"_pik_q"$i".png)
    compression_rate=$(echo "(($orig_size - $new_size) / $orig_size) * 100" | bc -l)
    reference_compression_rate=$(echo "(($reference_jpg_size - $new_size) / $reference_jpg_size) * 100" | bc -l)
    printf -v compression_rate "%0.2f" "$compression_rate" #set to 2 dp
    printf -v reference_compression_rate "%0.2f" "$reference_compression_rate" #set to 2 dp
    echo "$i","$new_size","$butteraugli_score","$ssimulacra_score","$compression_rate","$reference_compression_rate" >> pik-"$filename".csv
  done
#End csv generation
}

function webp_near_lossless
{
  echo "Analysing Webp images(Near Lossless)[Source :$x]"
  rm -rf webp-"$filename".csv
#Start csv generation
  echo "Test_Image,Original_Size" >> webp-"$filename".csv
  echo "$filename","$orig_size" >> webp-"$filename".csv
  echo "Quality,Size(bytes),Butteraugli,Ssimulacra,Compression Rate(%),Reference Compression Rate(%)" >> webp-"$filename".csv
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
    butteraugli_score=$(butteraugli "$x" "$filename"_webp_q"$i".png)
    ssimulacra_score=$(ssimulacra "$x" "$filename"_webp_q"$i".png)
    compression_rate=$(echo "(($orig_size - $new_size) / $orig_size) * 100" | bc -l)
    reference_compression_rate=$(echo "(($reference_jpg_size - $new_size) / $reference_jpg_size) * 100" | bc -l)
    printf -v compression_rate "%0.2f" "$compression_rate" #set to 2 dp
    printf -v reference_compression_rate "%0.2f" "$reference_compression_rate" #set to 2 dp
    echo "$i","$new_size","$butteraugli_score","$ssimulacra_score","$compression_rate","$reference_compression_rate" >> webp-"$filename".csv
  done
#End csv generation
}

function webp_lossy
{
  echo "Analysing Webp images(Lossy)[Source :$x]"
  rm -rf webp-lossy-"$filename".csv
#Start csv generation
  echo "Test_Image,Original_Size" >> webp-lossy-"$filename".csv
  echo "$filename","$orig_size" >> webp-lossy-"$filename".csv
  echo "Quality,Size(bytes),Butteraugli,Ssimulacra,Compression Rate(%),Reference Compression Rate(%)" >> webp-lossy-"$filename".csv
  if [ "$only_csv" = false ]; then
    echo "Generating Webp images(Lossy)[Source :$x] in parallel"
    parallel  --will-cite 'cwebp -sharp_yuv   -mt -quiet -q "{1}" -m 6 "{2}"  -o "{3}"_webp_lossy_q"{1}".webp' ::: {100..70}  ::: "$x" ::: "$filename"
    parallel  --will-cite 'dwebp -mt -quiet "{1}"_webp_lossy_q{2}.webp -o "{1}"_webp_lossy_q{2}.png' ::: "$filename" ::: {100..70}
  fi
  echo "Perform comparisions and store results in webp-lossy-$filename.csv"
  for ((i=100; i>=70; i--))
  do
    #cwebp -sharp_yuv -pass 10 -mt -quiet -q "$i" -m 6 "$x"  -o "$filename"_webp_lossy_q"$i".webp
    #convert to png to allow comparision
    #dwebp -quiet "$filename"_webp_lossy_q"$i".webp -o "$filename"_webp_lossy_q"$i".png
    new_size=$(wc -c < "$filename"_webp_lossy_q"$i".webp)
    butteraugli_score=$(butteraugli "$x" "$filename"_webp_lossy_q"$i".png)
    ssimulacra_score=$(ssimulacra "$x" "$filename"_webp_lossy_q"$i".png)
    compression_rate=$(echo "(($orig_size - $new_size) / $orig_size) * 100" | bc -l)
    reference_compression_rate=$(echo "(($reference_jpg_size - $new_size) / $reference_jpg_size) * 100" | bc -l)
    printf -v compression_rate "%0.2f" "$compression_rate" #set to 2 dp
    printf -v reference_compression_rate "%0.2f" "$reference_compression_rate" #set to 2 dp
    echo "$i","$new_size","$butteraugli_score","$ssimulacra_score","$compression_rate","$reference_compression_rate" >> webp-lossy-"$filename".csv
  done
#End csv generation
}

function bpg_lossy
{
  echo "Analysing BPG images(x265 encoder - lossy)[Source :$x]"
  rm -rf bpg-"$filename".csv
  #Start csv generation
  echo "Test_Image,Original_Size" >> bpg-"$filename".csv
  echo "$filename","$orig_size" >> bpg-"$filename".csv
  echo "Quality,Size(bytes),Butteraugli,Ssimulacra,Compression Rate(%),Reference Compression Rate(%)" >> bpg-"$filename".csv
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
    butteraugli_score=$(butteraugli "$x" "$filename"_bpg_q"$i".png)
    ssimulacra_score=$(ssimulacra "$x" "$filename"_bpg_q"$i".png)
    compression_rate=$(echo "(($orig_size - $new_size) / $orig_size) * 100" | bc -l)
    reference_compression_rate=$(echo "(($reference_jpg_size - $new_size) / $reference_jpg_size) * 100" | bc -l)
    printf -v compression_rate "%0.2f" "$compression_rate" #set to 2 dp
    printf -v reference_compression_rate "%0.2f" "$reference_compression_rate" #set to 2 dp
    echo "$i","$new_size","$butteraugli_score","$ssimulacra_score","$compression_rate","$reference_compression_rate" >> bpg-"$filename".csv
  done
#End csv generation
}

function bpg_lossy_jctvc
{
  echo "Analysing BPG images(jctvc encoder - lossy)[Source :$x]"
  rm -rf bpg-jctvc-"$filename".csv
  #Start csv generation
  echo "Test_Image,Original_Size" >> bpg-jctvc-"$filename".csv
  echo "$filename","$orig_size" >> bpg-jctvc-"$filename".csv
  echo "Quality,Size(bytes),Butteraugli,Ssimulacra,Compression Rate(%),Reference Compression Rate(%)" >> bpg-jctvc-"$filename".csv
  if [ "$only_csv" = false ]; then
    echo "Generating BPG images(jctvc encoder - lossy)[Source :$x] in parallel"
    parallel --will-cite 'bpgenc -q "{1}" -f 444  -m 9 -e jctvc "{2}" -o "{3}"_bpg_jctvc_q{1}.bpg' ::: {0..37}  ::: "$x" ::: "$filename"
    parallel --will-cite 'bpgdec "{1}"_bpg_jctvc_q"{2}".bpg -o "{1}"_bpg_jctvc_q{2}.png' ::: "$filename" ::: {0..37}
  fi
  echo "Perform comparisions and store results in bpg-jctvc-$filename.csv"
  for ((i=0; i<=37; i++))
  do
    #bpgenc -q "$i" -f 444  -m 9 -e jctvc "$x" -o "$filename"_bpg_jctvc_q"$i".bpg
    #convert to png to allow comparision
    #bpgdec "$filename"_bpg_jctvc_q"$i".bpg -o "$filename"_bpg_jctvc_q"$i".png
    new_size=$(wc -c < "$filename"_bpg_jctvc_q"$i".bpg)
    butteraugli_score=$(butteraugli "$x" "$filename"_bpg_jctvc_q"$i".png)
    ssimulacra_score=$(ssimulacra "$x" "$filename"_bpg_jctvc_q"$i".png)
    compression_rate=$(echo "(($orig_size - $new_size) / $orig_size) * 100" | bc -l)
    reference_compression_rate=$(echo "(($reference_jpg_size - $new_size) / $reference_jpg_size) * 100" | bc -l)
    printf -v compression_rate "%0.2f" "$compression_rate" #set to 2 dp
    printf -v reference_compression_rate "%0.2f" "$reference_compression_rate" #set to 2 dp
    echo "$i","$new_size","$butteraugli_score","$ssimulacra_score","$compression_rate","$reference_compression_rate" >> bpg-jctvc-"$filename".csv
  done
#End csv generation
}

function flif_lossy
{
  echo "Analysing FLIF images(Lossy)[Source :$x]"
  rm -rf flif-lossy-"$filename".csv
  #Start csv generation
  echo "Test_Image,Original_Size" >> flif-lossy-"$filename".csv
  echo "$filename","$orig_size" >> flif-lossy-"$filename".csv
  echo "Quality,Size(bytes),Butteraugli,Ssimulacra,Compression Rate(%),Reference Compression Rate(%)" >> flif-lossy-"$filename".csv
  if [ "$only_csv" = false ]; then
    echo "Generating FLIF images(Lossy)[Source :$x] in parallel"
    parallel --will-cite 'flif --overwrite -e -E100 -Q"{1}"  "{2}" "{3}"_lossy_q"{1}".flif' ::: {100..0}  ::: "$x" ::: "$filename"
    parallel --will-cite 'flif -d "{1}"_lossy_q"{2}".flif "{1}"_flif_lossy_q{2}.png' ::: "$filename" ::: {100..0}
  fi
  echo "Perform comparisions and store results in flif-lossy-$filename.csv"
  for ((i=100; i>=0; i--))
  do
    #flif --overwrite -e -E100 -Q"$i"  "$x" "$filename"_lossy_q"$i".flif
    #convert to png to allow comparision
    #flif -d "$filename"_lossy_q"$i".flif "$filename"_flif_lossy_q"$i".png
    new_size=$(wc -c < "$filename"_lossy_q"$i".flif)
    butteraugli_score=$(butteraugli "$x" "$filename"_flif_lossy_q"$i".png)
    ssimulacra_score=$(ssimulacra "$x" "$filename"_flif_lossy_q"$i".png)
    compression_rate=$(echo "(($orig_size - $new_size) / $orig_size) * 100" | bc -l)
    reference_compression_rate=$(echo "(($reference_jpg_size - $new_size) / $reference_jpg_size) * 100" | bc -l)
    printf -v compression_rate "%0.2f" "$compression_rate" #set to 2 dp
    printf -v reference_compression_rate "%0.2f" "$reference_compression_rate" #set to 2 dp
    echo "$i","$new_size","$butteraugli_score","$ssimulacra_score","$compression_rate","$reference_compression_rate" >> flif-lossy-"$filename".csv
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

      if [ "$x" == "--get-info" ]; then
        print_software_stack
        continue
      fi


    done

  fi

  files_to_zip=""
  for x in "$@"; do
    #skip if we are not dealing with an image
    if [ "${x: 0:2}" == "--" ]; then
      continue
    fi
    filename=$(basename "$x")
    orig_size=$(wc -c < "$x")
    #convert "$x" -quality 93 -sampling-factor 1x1  "$filename"_libjpeg_reference.jpg
    convert "$x" "$x".ppm # libjpeg will require ppm file as input
    jpeg -q 93 -oz -v -qt 2 -h  "$x".ppm "$filename"_libjpeg_reference.jpg
    reference_jpg_size=$(wc -c < "$filename"_libjpeg_reference.jpg)


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

    if [ "$only_bpg_lossy_jctvc" = true ] || [ "$only_csv" = true ]  || [ "$has_options" = false ]; then
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
    files_to_zip+="libjpeg-${filename}.csv libjpeg-2000-${filename}.csv guetzli-${filename}.csv pik-${filename}.csv av1-${filename}.csv webp-${filename}.csv webp-lossy-${filename}.csv  bpg-${filename}.csv flif-lossy-${filename}.csv mozjpeg-${filename}.csv bpg-jctvc-${filename}.csv ${filename}_butteraugli_plot.png ${filename}_ssimulacra_plot.png "
  done


  #Create a zip to store the results
  zipfile_name=result_corpus_with_plots$(date "+%Y.%m.%d-%H.%M.%S").zip
  zip "$zipfile_name" $files_to_zip
  current_dir=$(pwd)/"$zipfile_name"
  echo "Success! Download results : $current_dir"
}

main "$@"
