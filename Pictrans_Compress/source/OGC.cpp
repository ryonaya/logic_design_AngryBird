#include <iostream>
#include <fstream>
#include <map>
#include <iomanip>
using namespace std;

map<string, int> encode;

int main () {
    string coeName;
    int bitCount;
    int width, height;

    cout << "Input : A COE file name (without file extension)" << '\n';
    cin >> coeName;
    ifstream coefile (coeName + ".coe");
        if(!coefile.is_open()){
            cout << "Fuck you !" << '\n';
            return 0;
        }
    cout << "Input : How many bits per color ? ( 1 ~ 12 )" << '\n';
    cin >> bitCount;
        if(bitCount < 1 || bitCount > 12){
            cout << "Fuck you !" << '\n';
            return 0;
        }
    cout << "Input : Width" << '\n';
    cin >> width;
        if(width < 0 || width > 2160){
            cout << "Fuck you !" << '\n';
            return 0;
        }
    cout << "Input : Height" << '\n';
    cin >> height;
        if(height < 0 || height > 1800){
            cout << "Fuck you !" << '\n';
            return 0;
        }

    ofstream txtfile ("file.txt", ios::trunc);
    ofstream mappingfile ("mapping.txt", ios::trunc);
    if(txtfile.is_open() && mappingfile.is_open()){
        string cur;
        string arr[1050];
        getline(coefile, cur);
        getline(coefile, cur);
        txtfile << "memory_initialization_radix=2;" << '\n';
        txtfile << "memory_initialization_vector=" << '\n';

        mappingfile << "module " + coeName + "_pixel_decode(\n";
        mappingfile << "    input  [" << bitCount << "-1:0]  pre_" + coeName + "_pixel,\n";
        mappingfile << "    output [12-1:0] " + coeName + "_pixel\n";
        mappingfile << ");\n\n";

        int cnt = 0, totalCnt = 0;
        while(getline(coefile, cur)){
            if(cur.back() == ';') cur.back() = ',';
            auto iter = encode.find(cur);
            if(iter == encode.end()){
                encode.insert(pair<string, int>(cur, cnt));
                if(cnt > 1<<(bitCount)){
                    cout << "Fuck you !" << '\n';
                    return 0;
                }
                arr[cnt++] = "    12'h" + cur;
            }
            string x;
            int tmp = iter->second;
            for(int i=bitCount-1; i>=0; i--)
                x += (tmp & (1<<i))/(1<<i) + '0';

            totalCnt++;
            if(totalCnt < width*height)
                txtfile << x << ",\n";
            else
                txtfile << x << ";\n";
        }
        mappingfile << "parameter [12-1:0] list [0:" << cnt-1 << "] = {\n";

        for(int i=0; i<cnt-1; i++)
            mappingfile << arr[i] << '\n';
        arr[cnt-1].back() = ' ';
        mappingfile << arr[cnt-1] << '\n';

        mappingfile << "};\n";
        mappingfile << "assign " + coeName + "_pixel = list[pre_" + coeName + "_pixel];\n";
        mappingfile << "\nendmodule";

    }
    else{
        cout << "failed to open file.txt!!!" << '\n';
        exit(0);
    }

    coefile.close();
    txtfile.close();
    return 0;
}
