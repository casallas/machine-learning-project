/**
 * @authors Keji Hu, Ashwin Natarajan
 */
import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileWriter;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Scanner;

public class parsing_data_new {
	// private String toParse;
	private double time;
	private boolean trials = false;
	private boolean firstInstanceinTrial = false;
	private int noofcoll = 0;
	private int numballs;
	private int[] collisions;
	private String ballPositionsandSizeData;
	private ArrayList<String> positions;
	private FileWriter fw;
	private int lineNumber = 0;
	private int numberOfTrials = 0;

	public parsing_data_new(int numballs, FileWriter fw) {
		// this.toParse = line;
		ballPositionsandSizeData = "";
		this.numballs = numballs;
		collisions = new int[numballs];
		positions = new ArrayList<String>();
		this.fw = fw;
	}

	public String toString() {
		int size = positions.size();
		String str = time + "," + positions.get(0) + ","
				+ positions.get(size / 3) + "," + positions.get(size / 2) + "," + ballPositionsandSizeData + ",";
		for (int i = 0; i < numballs; i++) {
			str += collisions[i];
			if(i < numballs - 1)
				str += ",";
		}
		return str + "\n";
	}

	public void scan(String toParse) {
		lineNumber++;
		if (toParse.startsWith("<new_trial/>"))
			numberOfTrials++;
		if (toParse.startsWith("<new_trial/>") && trials == false) {
			trials = true;
		} else if ((toParse.startsWith("<no_more_spheres/>") || toParse.startsWith("<balls_bypassed_user/>") ) && trials == true) {
			// trials = false;
			try {
				//System.out.println(lineNumber);
				fw.write(this.toString());
				//System.out.println("Written output for" + numberOfTrials);
				firstInstanceinTrial = false;
			} catch (IOException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}
			time = 0;
			this.noofcoll = 0;
			collisions = new int[numballs];
			positions = new ArrayList<String>();
			ballPositionsandSizeData = "";
		} else if (toParse.startsWith("<collision sphere=")) {
			this.noofcoll++;
			int index = toParse.charAt(toParse.indexOf('=') + 1) - '0';
			collisions[index - 1] = this.noofcoll;
		} else if (toParse.charAt(0) <= '9' && toParse.charAt(0) >= '0'
				&& trials) {
			if (this.noofcoll == 0) {
				String[] features = toParse.split(",");
				String requiredFeatures = features[1] + "," + features [2] + "," + features[3] + "," + features[4];
				if (firstInstanceinTrial == false){
					firstInstanceinTrial = true;
				ballPositionsandSizeData = features[5] + ",";
				for(int ballsnum = 0; ballsnum < numballs; ballsnum++){
					String ballSize = features[6 + ballsnum].split("_")[1];
					String ballPositions = features[6 + ballsnum].split("_")[2];
				    ballPositionsandSizeData += ballSize + "," + ballPositions.split(" ")[0] + "," + ballPositions.split(" ")[1] + "," + ballPositions.split(" ")[2];
				    if(ballsnum < numballs - 1)
					ballPositionsandSizeData += ",";
				}
				}
				positions.add(requiredFeatures);
				String times = toParse.split(",")[0];
				time += Double.parseDouble(times);
			}
		} else {
			// skip
		}
	}

	public int getNumberOfTrials(){
		return numberOfTrials;
	}

	public static void main(String[] args) {
		// check for
		if (args.length != 3) {
			System.err.println("incorrect number of arguments");
			return;
		}
		// create file scanner for input file
		File fin = new File(args[0]);
        int numberOfBalls = Integer.parseInt(args[1]);
		File fout = new File(args[2]);
		FileWriter fw = null;
		try {
			fw = new FileWriter(fout);
			String ballsHeader = "";
			if(numberOfBalls == 3)
				ballsHeader = "ball1_size,ball1_0_x, ball1_0_y, ball1_0_z, ball2_size, ball2_0_x, ball2_0_y, ball2_0_z," +
						"ball3_size, ball3_0_x, ball3_0_y, ball3_0_z, collision1, collision2, collision3";
			if(numberOfBalls == 2)
				ballsHeader = "ball1_size,ball1_0_x, ball1_0_y, ball1_0_z, ball2_size, ball2_0_x, ball2_0_y, ball2_0_z," +
						"collision1, collision2";
			if(numberOfBalls == 1)
				ballsHeader = "ball1_size,ball1_0_x, ball1_0_y, ball1_0,z," +
						 "collision1";
			fw.write("total_time,head_position_0_x,head_position_0_y,head_position_0_z," +
					"head_orientation_0_x,head_orientation_0_y,head_orientation_0_z,head_orientation_0_w,"  +
					"wand_position_0_x,wand_position_0_y,wand_position_0_z," +
					"wand_orientation_0_x,wand_orientation_0_y,wand_orientation_0_z,wand_orientation_0_w," +
					"head_position_i3_x,head_position_i3_y,head_position_i3_z," +
					"head_orientation_i3_x,head_orientation_i3_y,head_orientation_i3_z,head_orientation_i3_w," +
					"wand_position_i3_x,wand_position_i3_y,wand_position_i3_z," +
					"wand_orientation_i3_x,wand_orientation_i3_y,wand_orientation_i3_z,wand_orientation_i3_w," +
					"head_position_i3_x,head_position_i3_y,head_position_i3_z," +
					"head_orientation_i3_x,head_orientation_i3_y,head_orientation_i3_z,head_orientation_i3_w," +
					"wand_position_i3_x,wand_position_i3_y,wand_position_i3_z," +
					"wand_orientation_i3_x,wand_orientation_i3_y,wand_orientation_i3_z,wand_orientation_i3_w," +
					"numballs," + ballsHeader + "\n");
		} catch (IOException e1) {
			// TODO Auto-generated catch block
			e1.printStackTrace();
		}
		parsing_data_new pd = new parsing_data_new(Integer.parseInt(args[1]), fw);
		Scanner scan = null;
		try {
			scan = new Scanner(fin);
		} catch (FileNotFoundException e) {
			System.err.println("can not open the file: " + args[0]);
			return;
		}

		// scanning file
		String line = null;
		while (scan.hasNextLine()) {
			line = scan.nextLine();
			pd.scan(line);
		}

		try{
		//fw.write(pd.toString());
			fw.close();
			//System.out.println(pd.getNumberOfTrials());
		}catch (IOException e){
			System.err.println("IO Exception" + args[0]);
			return;
		}
	}

}
