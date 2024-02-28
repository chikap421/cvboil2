inputDir = "/Users/chikamaduabuchi/Documents/paul/processed/algorithm2";
outputDir = "/Users/chikamaduabuchi/Documents/paul/segmentation2";
list = getFileList(inputDir);

for (i = 0; i < list.length; i++) {
    if (endsWith(list[i], ".tif")) {
        open(inputDir + "/" + list[i]);
        call('de.unifreiburg.unet.SegmentationJob.processHyperStack', 'modelFilename=/Users/chikamaduabuchi/Desktop/cell caffemodels/2d_cell_net_v0.modeldef.h5,Tile shape (px):=500x500,weightsFilename=/home/ubuntu/img_3.caffemodel.h5,gpuId=GPU 0,useRemoteHost=true,hostname=ec2-34-229-46-106.compute-1.amazonaws.com,port=22,username=ubuntu,RSAKeyfile=/Users/chikamaduabuchi/Desktop/Key pairs/chika-key-pair.pem,processFolder=,average=none,keepOriginal=true,outputScores=false,outputSoftmaxScores=false');
        run("8-bit");
        saveAs("Tiff", outputDir + "/" + list[i]);
        close('*');
    }
}
print("Segmentation complete for all images.");