from bs4 import BeautifulSoup as bs
import requests
import re

# Regex to extract the platforms names out of img tags' "alt" attribute
_platform_name_re='(.*)(\s+(Icon|Log|Logo)$)'

class Solution:
    """Model for a solution definition. Its __str__ function defines how it will be written on the output file."""
    def __init__(self, category, service, platform, name, description):
        self.category = category
        self.service = service
        self.platform = platform
        self.name = name
        self.description = description

    def __str__(self):
        return '%s,%s,%s,%s,%s'%(self.category, self.service, self.platform, self.name, self.description)


def get_table_rows(webpage):
    """Extracts every row out of the table and returns them as a list"""
    page = requests.get(webpage).content
    bspage = bs(page, 'html.parser')
    table = bspage.find('table', {'id':'comparison'})
    return table.find_all('tr')


def get_table_headers(rows):
    """Parses the plaftforms names at the header of the table and return them as a list"""
    first_row=rows[0]
    img_tags = first_row.find_all('img')
    return [get_platform_name(img_tag['alt']) for img_tag in img_tags]


def get_platform_name(alt_desc):
    """Extracts the platform name out of an img tag's alt attribute"""
    n = re.match(_platform_name_re, alt_desc)
    return n.group(1) if n is not None else alt_desc


def get_table_data(rows):
    """Returns a list with all the parsed solutions from the rows"""
    ordered_platforms_names = get_table_headers(rows)
    rows=rows[1:]  # Table headers are not needed anymore
    all_solutions = []
    for row in rows:
        columns = row.find_all('td')
        category = columns[0].text
        service = columns[1].text
        columns = columns[2:]
        for i, column in enumerate(columns):
            unparsed_solutions = [link for link in column.find_all('a')]
            for unparsed_solution in unparsed_solutions:
                if len(unparsed_solution.text):
                    parsed_solution = Solution(
                            category=category,
                            service=service,
                            platform=ordered_platforms_names[i],
                            name=unparsed_solution.text,
                            description=unparsed_solution['href'] 
                        )
                    all_solutions.append(parsed_solution)
    return all_solutions      


def get_all_solutions(webpage):
    """Parses the table from the webpage and returns a list with all the cloud solutions found"""
    table_rows = get_table_rows(webpage)
    return get_table_data(table_rows)


if __name__ == '__main__':
    webpage='https://comparecloud.in/'
    output_file='./clouds.csv'
    solutions = get_all_solutions(webpage)
    csv_headers=['Category', 'Service', 'Platform', 'Solution','Description']
    csv_content='\n'.join([str(solution) for solution in solutions])
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(','.join(csv_headers))
        f.write('\n') # needs to \n between the headers and the content
        f.write(csv_content)
