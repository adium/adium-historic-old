//
//  JoscarFileMapper.java
//  joscar Java Bridge
//
//  Created by Evan Schoenberg on 2/19/06.
//

package net.adium.joscarBridge;

import net.kano.joustsim.oscar.oscar.service.icbm.ft.FileMapper;
import net.kano.joscar.rvcmd.SegmentedFilename;
import java.io.File;

public class JoscarFileMapper implements FileMapper
{
	private boolean useIndicatedNames = false;
	private String path;
	private static final String separator = System.getProperty("file.separator");

	/*
	 * If shouldUseIndicatedNames is YES, we will use the names we are passed if possible, appending them to inPath.
	 * If it is NO, inPath should be an actual file name which will be used.  Note that shouldUseIndicatedNames should only be
	 * NO if only one file is going to come through this FileMapper
	 */
	public JoscarFileMapper(boolean	shouldUseIndicatedNames, String inPath) {
		useIndicatedNames = shouldUseIndicatedNames;
		path = inPath;
	}

	public File getDestinationFile(SegmentedFilename filename) {
		File destinationFile;

		if (useIndicatedNames) {
			//Add the separator to the end if necessary
			if (!(path.endsWith(separator))) {
				path = path.concat(separator);
			}
			
			destinationFile = new File(path.concat(filename.toNativeFilename()));
		} else {
			destinationFile = new File(path);
		}
		
		return destinationFile;
	}
	
	public File getUnspecifiedFilename() {
		return new File(path);
	}
}
