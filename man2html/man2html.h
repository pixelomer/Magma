//
//  man2html.h
//  Magma
//
//  Created by PixelOmer on 22.07.2019.
//  Copyright © 2019 PixelOmer. All rights reserved.
//

#ifndef man2html_h
#define man2html_h

/*!	@brief      Parses the manpage and writes it to a file in HTML format.
	@discussion This function is not thread-safe.
	@param      input_file Full path to the input file.
	@param      output_file Full path to the output file. */
BOOL parse_manpage(const char *input_file, const char *output_file);

#endif /* man2html_h */
