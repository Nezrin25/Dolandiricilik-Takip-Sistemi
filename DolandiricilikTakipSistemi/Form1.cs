using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;
using System.Data.SqlClient;

namespace DolandiricilikTakipSistemi
{
    public partial class Form1 : Form
    {
        public Form1()
        {
            InitializeComponent();
        }

        private void button1_Click(object sender, EventArgs e)
        {
            string baglantiCumlesi = @"Data Source=NEZRIN\NEZSQL; Initial Catalog=DolandiricilikTespit; Integrated Security=True";
            using (SqlConnection baglanti = new SqlConnection(baglantiCumlesi))
            {
                try
                {
                    baglanti.Open();
                    // SQL'de yazdığımız prosedürü çağırıyoruz
                    SqlCommand komut = new SqlCommand("sp_RiskliIslemleriListele", baglanti);
                    komut.CommandType = System.Data.CommandType.StoredProcedure;

                    SqlDataAdapter da = new SqlDataAdapter(komut);
                    System.Data.DataTable dt = new System.Data.DataTable();
                    da.Fill(dt);

                    // Verileri eklediğin tabloya aktarır
                    dataGridView1.DataSource = dt;
                    MessageBox.Show("Sistem Aktif: Riskli İşlemler Listelendi!");
                }
                catch (Exception ex)
                {
                    MessageBox.Show("Bağlantı Hatası: " + ex.Message);
                }
            }
        }
    }
}
