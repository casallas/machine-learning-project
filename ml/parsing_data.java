/**
 * @author Keji Hu
 */
import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileWriter;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Scanner;

public class parsing_data {
	// private String toParse;
	private double time;
	private boolean trials = false;
	private int noofcoll = 0;
	private int numballs;
	private int[] collisions;
	private ArrayList<String> positions;
	private FileWriter fw;

	public parsing_data(int numballs, FileWriter fw) {
		// this.toParse = line;
		this.numballs = numballs;
		collisions = new int[numballs];
		positions = new ArrayList<String>();
		this.fw = fw;
	}

	public String toString() {
		int size = positions.size();
		String str = time + "\n" + positions.get(0) + "\n"
				+ positions.get(size / 3) + "\n" + positions.get(size / 2)
				+ "\n";
		for (int i = 0; i < numballs; i++) {
			str += collisions[i] + " ";
		}
		return str;
	}

	public void scan(String toParse) {
		if (toParse.startsWith("<new_trial/>") && trials == false) {
			trials = true;
		} else if (toParse.startsWith("<new_trial/>") && trials == true) {
			// trials = false;
			try {
				fw.write(this.toString());
			} catch (IOException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}
			time = 0;
			this.noofcoll = 0;
			collisions = new int[numballs];
			positions = new ArrayList<String>();
		} else if (toParse.startsWith("<collision sphere=")) {
			this.noofcoll++;
			int index = toParse.charAt(toParse.indexOf('=') + 1) - '0';
			collisions[index - 1] = this.noofcoll;
		} else if (toParse.charAt(0) <= '9' && toParse.charAt(0) >= '0'
				&& trials) {
			if (this.noofcoll == 0) {
				positions.add(toParse);
				String times = toParse.split(",")[0];
				time += Double.parseDouble(times);
			}
		} else {
			// skip
		}
	}

	public static void main(String[] args) {
		// check for
		if (args.length != 3) {
			System.err.println("incorrect number of arguments");
			return;
		}
		// create file scanner for input file
		File fin = new File(args[0]);

		File fout = new File(args[2]);
		FileWriter fw = null;
		try {
			fw = new FileWriter(fout);
		} catch (IOException e1) {
			// TODO Auto-generated catch block
			e1.printStackTrace();
		}
		parsing_data pd = new parsing_data(Integer.parseInt(args[1]), fw);
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
	}

}
